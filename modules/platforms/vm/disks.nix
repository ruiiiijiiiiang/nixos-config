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
      type = types.ints.positive;
      default = 50;
      description = "Primary disk size for the guest VM in GB.";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices.disk = {
      primary = {
        type = "disk";
        device = "/dev/vda";
        imageSize = "50G";
        content = {
          type = "gpt";
          partitions = {
            inherit (hardware.partitions) ESP root;
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
        ];
      }
    ) hardware.storage.external;
  };
}
