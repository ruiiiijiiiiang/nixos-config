{
  config,
  consts,
  inputs,
  lib,
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
    enable = mkEnableOption "Enable VM disk layout";
    size = mkOption {
      type = types.str;
      default = "50GB";
      description = "Primary disk size for the guest VM.";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices.disk = {
      primary = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            ESP = hardware.partitions.esp;
            inherit (hardware.partitions) root;
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
