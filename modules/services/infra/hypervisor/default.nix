{
  config,
  consts,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts)
    username
    ports
    hardware
    virtualization
    vlan-ids
    ;
  cfg = config.custom.services.infra.hypervisor;
  vlanInterface = "${cfg.lanBridge}.${toString cfg.vlanId}";
  spicePorts = lib.mapAttrsToList (_: port: port) ports.spice;

  shutdownHypervisorScriptText = lib.readFile ./shutdown-hypervisor.sh;

  shutdownHypervisorScript = pkgs.writeShellApplication {
    name = "shutdown-hypervisor";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      libvirt
      systemd
    ];
    text = shutdownHypervisorScriptText;
  };

  nixvirtDefaults = {
    memoryBacking = {
      source.type = "memfd";
      access.mode = "shared";
    };
    devices = {
      filesystem = lib.mapAttrsToList (name: _: {
        type = "mount";
        accessmode = "passthrough";
        driver.type = "virtiofs";
        binary.xattr = true;
        source.dir = "/mnt/external/${name}";
        target.dir = name;
      }) hardware.storage.external;
    };
  };

  mkInterface = name: vlan: {
    type = "bridge";
    mac.address = (virtualization.${name} or { }).mac or "";
    source.bridge = cfg.lanBridge;
    model.type = "virtio";
    inherit vlan;
  };

  mkGuest =
    name: guestCfg:
    let
      networkInterface = lib.optional (guestCfg.vlan != null) (mkInterface name guestCfg.vlan);
      mergedNixvirtConfigs = lib.recursiveUpdate guestCfg.nixvirtExtraConfigs {
        devices = {
          interface = networkInterface ++ (guestCfg.nixvirtExtraConfigs.devices.interface or [ ]);
        };
      };
      vmVirt = virtualization.${name} or { };
    in
    {
      nixosConfig = inputs.self.nixosConfigurations.${name};
      cpu = vmVirt.cpu or 1;
      memory = vmVirt.memory or 512;
      storage = vmVirt.storage or { };
      uuid = vmVirt.uuid or "";
      inherit (guestCfg) autoStart pciDevices;
      nixvirtExtraConfigs = mergedNixvirtConfigs;
    };

  guests = lib.mapAttrs mkGuest cfg.guests;

  gpuGuest =
    let
      gpuGuests = lib.filterAttrs (
        _: guest: lib.any (dev: dev.id == consts.hardware.gpu.id) (guest.pciDevices or [ ])
      ) guests;
    in
    if gpuGuests == { } then null else lib.head (lib.attrNames gpuGuests);
in
{
  imports = [
    inputs.nixos-vm-provisioner.nixosModules.host-base
    inputs.NixVirt.nixosModules.default
  ];

  options.custom.services.infra.hypervisor = with lib; {
    enable = mkEnableOption "Enable libvirt hypervisor host";
    lanBridge = mkOption {
      type = types.str;
      default = "br0";
      description = "LAN bridge name.";
    };
    vlanId = mkOption {
      type = types.ints.positive;
      default = vlan-ids.infra;
      description = "VLAN ID for infra.";
    };
    volumeGroup = mkOption {
      type = types.str;
      default = "vg-nvme";
      description = "LVM volume group name.";
    };
    guests = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            autoStart = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to start the VM automatically.";
            };
            pciDevices = mkOption {
              type = types.listOf types.attrs;
              default = [ ];
              description = "PCI devices to pass through to the VM.";
            };
            vlan = mkOption {
              type = types.nullOr types.attrs;
              default = null;
              description = "VLAN bridge configuration.";
            };
            nixvirtExtraConfigs = mkOption {
              type = types.attrs;
              default = { };
              description = "Extra nixvirt configurations.";
            };
          };
        }
      );
      default = { };
      description = "Attribute set of VM names and their configurations.";
    };
    guestVms = mkOption {
      type = types.listOf types.str;
      default = builtins.attrNames cfg.guests;
      defaultText = "builtins.attrNames config.custom.services.infra.hypervisor.guests";
      description = "List of guest VM names.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      let
        guestNames = builtins.attrNames cfg.guests;
      in
      (map (name: {
        assertion = builtins.hasAttr name virtualization;
        message = "The guest VM '${name}' configured under 'custom.services.infra.hypervisor.guests' is not defined in the 'virtualization' constants inside 'lib/consts.nix'.";
      }) guestNames)
      ++ (map (name: {
        assertion =
          !(builtins.hasAttr name virtualization)
          || (
            builtins.hasAttr "cpu" virtualization.${name}
            && builtins.hasAttr "memory" virtualization.${name}
            && builtins.hasAttr "storage" virtualization.${name}
            && builtins.hasAttr "uuid" virtualization.${name}
          );
        message = "The guest VM '${name}' inside 'virtualization' constants must define 'cpu', 'memory', 'storage', and 'uuid'.";
      }) guestNames)
      ++ (map (name: {
        assertion =
          !(builtins.hasAttr name virtualization && cfg.guests.${name}.vlan != null)
          || (builtins.hasAttr "mac" virtualization.${name});
        message = "The guest VM '${name}' has VLAN networking configured but does not define a 'mac' address inside 'virtualization' constants.";
      }) guestNames);

    environment.systemPackages = with pkgs; [
      pciutils
      shutdownHypervisorScript
      usbutils
      virtiofsd
    ];

    boot = {
      kernelModules = [
        "kvm-amd"
      ];
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
      ];
    };

    virtualisation = {
      libvirtd = {
        qemu = {
          vhostUserPackages = with pkgs; [ virtiofsd ];
        };
        dbus.enable = true;
        allowedBridges = [ cfg.lanBridge ];
      };

      nixos-vm-provisioner = {
        enable = true;
        inherit (cfg) volumeGroup;
        inherit nixvirtDefaults guests;
      };
    };

    users.users = {
      ${username}.extraGroups = [ "libvirtd" ];
      libvirtdbus.extraGroups = [ "libvirtd" ];
    };

    networking.firewall = {
      interfaces.${vlanInterface} = {
        allowedTCPPorts = spicePorts;
      };
    };

    # In case I ever need to plug in an HDMI cable to natively troubleshoot
    systemd.services."delayed-gpu-guest-start" = lib.mkIf (gpuGuest != null) {
      description = "Start ${gpuGuest} with a 5-minute delay";
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 300 && ${pkgs.libvirt}/bin/virsh start ${gpuGuest}'";
        RemainAfterExit = true;
      };
    };
  };
}
