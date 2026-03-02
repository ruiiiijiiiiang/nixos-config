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
  volumeGroupCfg = config.custom.roles.hypervisor.libvirt.volumeGroup;

  guestLVs =
    lib.mapAttrs
      (name: sys: {
        inherit (sys.config.custom.platforms.vm.disks) size;
      })
      lib.filterAttrs
      (name: sys: sys.config.custom.platforms.vm.libvirt.enable or false)
      nixosConfigurations;
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.custom.platforms.minipc.disks = with lib; {
    enable = mkEnableOption "Minipc disks config";
  };

  config = lib.mkIf cfg.enable {
    disko.devices = {
      disk = {
        nvme0 = {
          type = "disk";
          device = "/dev/disk/by-id/${hardware.storage.internal.nvme-ssd-0.id}";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              lvm = lib.mkIf volumeGroupCfg.enable {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = volumeGroupCfg.name;
                };
              };
            };
          };
        };

        nvme1 = {
          type = "disk";
          device = "/dev/disk/by-id/${hardware.storage.internal.nvme-ssd-1.id}";
          content = {
            type = "gpt";
            partitions = {
              lvm = lib.mkIf volumeGroupCfg.enable {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = volumeGroupCfg.name;
                };
              };
            };
          };
        };
      };

      lvm_vg = lib.mkIf volumeGroupCfg.enable {
        ${volumeGroupCfg.name} = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "50G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          }
          // guestLVs;
        };
      };
    };

    fileSystems = lib.mapAttrs' (
      name: device:
      lib.nameValuePair device.path {
        device = device.id;
        fsType = "ext4";
      }
    ) hardware.storage.external;
  };
}
