{
  config,
  consts,
  helpers,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) username ports hardware;
  inherit (helpers) parsePciAddress;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.infra.hypervisor;
  vlanInterface = "${cfg.lanBridge}.${toString cfg.vlanId}";
  spicePorts = lib.mapAttrsToList (_: port: port) ports.spice;

  getPassthroughGuest =
    hardware:
    let
      guestConfigs = lib.filterAttrs (name: _: lib.elem name cfg.guestVms) nixosConfigurations;
      matching = lib.filterAttrs (
        _: nixosConfiguration:
        nixosConfiguration.config.custom.platforms.vm.kernel.hardwarePassthrough == hardware
      ) guestConfigs;
    in
    if matching == { } then null else lib.head (lib.attrNames matching);

  passthroughIds =
    lib.concatMap (hw: lib.optional (getPassthroughGuest hw != null) hardware.${hw}.id)
      [
        "gpu"
        "nic"
      ];

  gpuGuest = getPassthroughGuest "gpu";

  mkLibvirtBase =
    { guest, libvirtCfg }:
    {
      vcpu.placement = "static";

      os = {
        loader = {
          readonly = true;
          secure = false;
          type = "pflash";
          # This path needs to be hardcoded otherwise it defaults to edk2-x86_64-secure-code.fd and enables secure boot.
          # I've tried other methods to disable secure boot and setting this path is the only way that worked.
          path = "/run/libvirt/nix-ovmf/edk2-x86_64-code.fd";
        };
      };

      memoryBacking = {
        source.type = "memfd";
        access.mode = "shared";
      };

      devices = {
        disk = [
          {
            type = "block";
            device = "disk";
            driver = {
              name = "qemu";
              type = "raw";
              cache = "none";
              io = "native";
              discard = "unmap";
            };
            source.dev = "/dev/${cfg.volumeGroup}/${guest}";
            target = {
              dev = "vda";
              bus = "virtio";
            };
          }
        ];

        filesystem = lib.mapAttrsToList (name: _: {
          type = "mount";
          accessmode = "passthrough";
          driver.type = "virtiofs";
          binary.xattr = true;
          source.dir = "/mnt/external/${name}";
          target.dir = name;
        }) hardware.storage.external;

        interface = [
          {
            type = "bridge";
            mac = {
              address = hardware.macs.${guest};
            };
            source = {
              bridge = cfg.lanBridge;
            };
            vlan = {
              tag = [ { id = libvirtCfg.vlanId; } ];
            };
            model = {
              type = "virtio";
            };
          }
        ];

        hostdev =
          let
            inherit (nixosConfigurations.${guest}.config.custom.platforms.vm.kernel) hardwarePassthrough;
          in
          lib.optionals (hardwarePassthrough != null) [
            {
              mode = "subsystem";
              type = "pci";
              managed = true;
              source = {
                address = parsePciAddress hardware.${hardwarePassthrough}.address;
              };
            }
          ];

        serial = [
          {
            type = "pty";
            target = {
              type = "isa-serial";
              port = 0;
            };
          }
        ];

        console = [
          {
            type = "pty";
            target = {
              type = "serial";
              port = 0;
            };
          }
        ];

        panic = [
          {
            model = "isa";
          }
        ];
      };
    };
in
{
  imports = [
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
    guestVms = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Guest VM names to define.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          let
            missing = lib.filter (guest: !(lib.hasAttr guest nixosConfigurations)) cfg.guestVms;
          in
          missing == [ ];
        message = "Unknown nixosConfigurations entries found in libvirt.guestVms.";
      }
      {
        assertion = lib.all (
          guest:
          (lib.hasAttr guest nixosConfigurations)
          && (nixosConfigurations.${guest}.config.custom.platforms.vm.libvirt.enable or false)
        ) cfg.guestVms;
        message = "Every libvirt guest must enable custom.platforms.vm.libvirt.";
      }
    ];

    environment.systemPackages = with pkgs; [
      pciutils
      usbutils
      virtiofsd
    ];

    virtualisation = {
      libvirtd = {
        qemu = {
          runAsRoot = true;
          package = pkgs.qemu_kvm;
          vhostUserPackages = with pkgs; [ virtiofsd ];
          verbatimConfig = ''
            user = "root"
            group = "root"
          '';
        };
        dbus.enable = true;
        allowedBridges = [ cfg.lanBridge ];
      };

      libvirt = {
        enable = true;
        connections."qemu:///system" = {
          domains = map (
            guest:
            let
              inherit (nixosConfigurations.${guest}) config;
              libvirtCfg = config.custom.platforms.vm.libvirt;
            in
            {
              active = libvirtCfg.autoStart;
              definition = inputs.NixVirt.lib.domain.writeXML (
                lib.foldl' lib.recursiveUpdate { } [
                  (inputs.NixVirt.lib.domain.templates.linux {
                    name = guest;
                    uuid = hardware.uuids.${guest};
                    vcpu.count = libvirtCfg.cpu;
                    memory = {
                      count = libvirtCfg.memory;
                      unit = "GiB";
                    };
                    virtio_video = null;
                  })
                  (mkLibvirtBase { inherit guest libvirtCfg; })
                  libvirtCfg.extraConfigs
                ]
              );
            }
          ) cfg.guestVms;
        };
      };
    };

    boot = lib.mkIf (passthroughIds != [ ]) {
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "vfio"
        "vfio_pci"
        "vfio-pci.ids=${lib.concatStringsSep "," passthroughIds}"
        "vfio_iommu_type1"
        "video=efifb:off"
      ];
      initrd.kernelModules = [
        "vfio"
        "vfio_pci"
        "vfio_iommu_type1"
      ];
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
