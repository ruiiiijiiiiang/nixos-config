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
  guestLvs = lib.genAttrs cfg.guestVms (guest: {
    size = "${toString nixosConfigurations.${guest}.config.custom.platforms.vm.disks.size}GB";
  });
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
        message = "Unknown nixosConfigurations entries found in guestVms.";
      }
      {
        assertion = lib.all (
          guest:
          (builtins.hasAttr guest nixosConfigurations)
          && (nixosConfigurations.${guest}.config.custom.platforms.vm.disks.enable or false)
        ) cfg.guestVms;
        message = "Every libvirt guest must enable custom.platforms.vm.disks.";
      }
    ];

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
