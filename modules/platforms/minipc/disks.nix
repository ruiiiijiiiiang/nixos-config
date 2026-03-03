{
  config,
  consts,
  inputs,
  lib,
  ...
}:
let
  inherit (consts) hardware;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.platforms.minipc.disks;

  guestLVs =
    let
      libvirtCfg = config.custom.roles.headless.hypervisor.libvirt;
    in
    lib.genAttrs libvirtCfg.guests (guest: {
      size = nixosConfigurations.${guest}.config.custom.platforms.vm.disks.size;
    });
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.custom.platforms.minipc.disks = with lib; {
    enable = mkEnableOption "Minipc disks config";
    volumeGroup = mkOption {
      type = types.str;
      default = "vg-nvme";
      description = "LVM volume group name";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices = {
      disk = {
        nvme0 = {
          type = "disk";
          device = "/dev/disk/by-id/${hardware.storage.internal.nvme-ssd-0}";
          content = {
            type = "gpt";
            partitions = {
              ESP = hardware.partitions.esp;
              lvm = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = cfg.volumeGroup;
                };
              };
            };
          };
        };

        nvme1 = {
          type = "disk";
          device = "/dev/disk/by-id/${hardware.storage.internal.nvme-ssd-1}";
          content = {
            type = "gpt";
            partitions = {
              lvm = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = cfg.volumeGroup;
                };
              };
            };
          };
        };
      };

      lvm_vg = {
        ${cfg.volumeGroup} = {
          type = "lvm_vg";
          lvs = {
            root = hardware.partitions.root // {
              size = "50G";
            };
          }
          // guestLVs;
        };
      };
    };

    fileSystems = lib.mapAttrs' (
      name: device:
      lib.nameValuePair "/mnt/${name}" {
        inherit device;
        fsType = "ext4";
      }
    ) hardware.storage.external;
  };
}
