{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.platforms.desktop.disks;
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.custom.platforms.desktop.disks = with lib; {
    enable = mkEnableOption "Enable Desktop disk layout";
    device = mkOption {
      type = types.str;
      default = "/dev/nvme0n1";
      description = "Disk device to partition.";
    };
    swapSize = mkOption {
      type = types.str;
      default = "32G";
      description = "Swap partition size.";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices = {
      disk = {
        main = {
          inherit (cfg) device;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                size = "512M";
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
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
              swap = {
                size = cfg.swapSize;
                content = {
                  type = "swap";
                  randomEncryption = false;
                  resumeDevice = true;
                };
              };
            };
          };
        };
      };
    };
  };
}
