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

  mkGuest =
    name: extra:
    {
      nixosConfig = inputs.self.nixosConfigurations.${name};
      cpu = virtualization.cpus.${name};
      memory = virtualization.memory.${name};
      storage = virtualization.storage.${name};
      uuid = virtualization.uuids.${name};
    }
    // extra;

  mkInterface = name: vlan: {
    type = "bridge";
    mac.address = virtualization.mac.${name};
    source.bridge = cfg.lanBridge;
    model.type = "virtio";
    inherit vlan;
  };

  guests = {
    vm-network = mkGuest "vm-network" {
      pciDevices = [
        {
          address = hardware.nic.address;
          id = hardware.nic.id;
        }
      ];
      nixvirtExtraConfigs = {
        devices.interface = [
          (mkInterface "vm-network" {
            trunk = true;
            tag = [
              {
                id = vlan-ids.home;
                nativeMode = "untagged";
              }
              { id = vlan-ids.infra; }
              { id = vlan-ids.dmz; }
            ];
          })
        ];
      };
    };

    vm-app = mkGuest "vm-app" {
      autoStart = false;
      pciDevices = [
        {
          address = hardware.gpu.address;
          id = hardware.gpu.id;
        }
      ];
      nixvirtExtraConfigs = {
        devices.interface = [
          (mkInterface "vm-app" {
            tag = [ { id = vlan-ids.infra; } ];
          })
        ];
      };
    };

    vm-monitor = mkGuest "vm-monitor" {
      nixvirtExtraConfigs = {
        devices.interface = [
          (mkInterface "vm-monitor" {
            tag = [ { id = vlan-ids.infra; } ];
          })
        ];
      };
    };

    vm-public = mkGuest "vm-public" {
      nixvirtExtraConfigs = {
        devices.interface = [
          (mkInterface "vm-public" {
            tag = [ { id = vlan-ids.dmz; } ];
          })
        ];
      };
    };

    vm-cyber = mkGuest "vm-cyber" {
      autoStart = false;
      nixvirtExtraConfigs = {
        devices = {
          interface = [
            (mkInterface "vm-cyber" {
              tag = [ { id = vlan-ids.dmz; } ];
            })
          ];
          graphics = [
            {
              type = "spice";
              autoport = false;
              port = consts.ports.spice.vm-cyber;
              listen = {
                type = "address";
                address = consts.addresses.any;
              };
            }
          ];
          channel = [
            {
              type = "spicevmc";
              target = {
                type = "virtio";
                name = "com.redhat.spice.0";
              };
            }
            {
              type = "unix";
              target = {
                type = "virtio";
                name = "org.qemu.guest_agent.0";
              };
            }
          ];
        };
      };
    };
  };

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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pciutils
      shutdownHypervisorScript
      usbutils
      virtiofsd
    ];

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
