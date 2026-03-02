{
  config,
  consts,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) hardware;
  cfg = config.custom.platforms.vm.disks;
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.custom.platforms.vm.disks = with lib; {
    enable = mkEnableOption "Enable disk config for VM";
    size = mkOption {
      type = types.str;
      default = "50GB";
      description = "Size of guest VM's main disk";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.virtiofsd ];

    disko.devices.disk = {
      primary = {
        type = "disk";
        device = "/dev/vda";
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
    };

    fileSystems = lib.mapAttrs' (
      name: device:
      lib.nameValuePair device.path {
        device = device.virtio-tag;
        fsType = "virtiofs";
        options = [
          "defaults"
          "nofail"
          "_netdev"
        ];
      }
    ) hardware.storage.external;
  };
}
