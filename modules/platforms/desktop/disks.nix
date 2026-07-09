{
  config,
  inputs,
  lib,
  consts,
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
  };

  config = lib.mkIf cfg.enable {
    disko.devices = {
      disk = {
        main = {
          device = "/dev/disk/by-id/${consts.hardware.storage.desktop.nvme-ssd-0}";
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
                size = "32G";
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

    fileSystems."/mnt/storage" = {
      device = "/dev/disk/by-id/${consts.hardware.storage.desktop.sata-ssd-0}-part1";
      fsType = "ext4";
      options = [
        "defaults"
        "nofail"
      ];
    };
  };
}
