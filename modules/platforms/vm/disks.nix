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
            ESP = hardware.partitions.esp;
            root = hardware.partitions.root;
          };
        };
      };
    };

    fileSystems = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "/mnt/${name}" {
        device = name;
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
