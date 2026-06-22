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
  guestLvs =
    lib.mapAttrs
      (name: guest: {
        size = guest.storage.size;
      })
      (
        lib.filterAttrs (name: guest: guest.storage.type == "lvm") (
          config.virtualisation.nixos-vm-provisioner.guests or { }
        )
      );
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.custom.platforms.minipc.disks = with lib; {
    enable = mkEnableOption "Enable MiniPC disk layout";
    volumeGroup = mkOption {
      type = types.str;
      default = "vg-nvme";
      description = "LVM volume group name.";
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
            root = {
              size = "50G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          }
          // guestLvs;
        };
      };
    };

    fileSystems = lib.mapAttrs' (
      name: device:
      lib.nameValuePair "/mnt/external/${name}" {
        device = "/dev/disk/by-id/${device}-part1";
        fsType = "ext4";
        options = [
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
        ];
      }
    ) hardware.storage.external;

    systemd.tmpfiles.rules = [
      "d /mnt/external 0755 - - - -"
    ]
    ++ lib.mapAttrsToList (name: _: "d /mnt/external/${name} 0755 - - - -") hardware.storage.external;
  };
}
