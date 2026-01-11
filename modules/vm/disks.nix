{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.custom.vm.disks;

  diskLayout = mountpoint: {
    type = "gpt";
    partitions = {
      bulk = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          inherit mountpoint;
          mountOptions = [
            "defaults"
            "nofail"
          ];
        };
      };
    };
  };
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.custom.vm.disks = with lib; {
    enableMain = mkEnableOption "Enable main drive (scsi0)";
    enableStorage = mkEnableOption "Enable storage drive (scsi1)";
    enableScratch = mkEnableOption "Enable scratch drive (scsi2)";
  };

  config = {
    disko.devices.disk = {
      main = mkIf cfg.enableMain {
        type = "disk";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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
          };
        };
      };

      storage = mkIf cfg.enableStorage {
        type = "disk";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
        content = diskLayout "/data";
      };

      scratch = mkIf cfg.enableScratch {
        type = "disk";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2";
        content = diskLayout "/bulk";
      };
    };

    fileSystems = {
      "/var" = mkIf cfg.enableStorage {
        device = "/data/var";
        options = [
          "bind"
          "nofail"
        ];
        depends = [ "/data" ];
      };

      "/home" = mkIf cfg.enableStorage {
        device = "/data/home";
        options = [
          "bind"
          "nofail"
        ];
        depends = [ "/data" ];
      };

      "/media" = mkIf cfg.enableScratch {
        device = "/bulk/media";
        options = [
          "bind"
          "nofail"
        ];
        depends = [ "/bulk" ];
      };
    };

    systemd.tmpfiles.rules =
      (lib.optionals cfg.enableStorage [
        "d /data/var 0755 root root -"
        "d /data/home 0755 root root -"
      ])
      ++ (lib.optionals cfg.enableScratch [
        "d /bulk/media 0755 root root -"
      ]);
  };
}
