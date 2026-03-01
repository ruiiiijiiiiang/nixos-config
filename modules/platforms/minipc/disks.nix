{
  config,
  consts,
  inputs,
  lib,
  ...
}:
let
  inherit (consts) hardware;
  cfg = config.custom.platforms.minipc.disks;
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
        main = {
          type = "disk";
          device = "/dev/disk/by-id/${hardware.storage.nvme-ssd-0}";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/vm_images" = {
                      mountpoint = "/var/lib/libvirt/images";
                      mountOptions = [
                        "nodatacow"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };

        storage = {
          type = "disk";
          device = "/dev/disk/by-id/${hardware.storage.usb-hdd-0}";
          content = {
            type = "gpt";
            partitions = {
              data = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/guest_data" = {
                      mountpoint = "/mnt/storage";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "nofail"
                      ];
                    };
                  };
                };
              };
            };
          };
        };

        backup = {
          type = "disk";
          device = "/dev/disk/by-id/${hardware.storage.usb-hdd-1}";
          content = {
            type = "gpt";
            partitions = {
              data = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/backups" = {
                      mountpoint = "/mnt/backups";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "nofail"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
