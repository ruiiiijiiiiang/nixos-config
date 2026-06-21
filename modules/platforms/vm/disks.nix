{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) hardware;
  cfg = config.custom.platforms.vm.disks;
in
{
  options.custom.platforms.vm.disks = with lib; {
    enable = mkEnableOption "Enable VM disk layout";
    swap = {
      enable = mkEnableOption "Enable swap file";
      size = mkOption {
        type = types.ints.positive;
        default = 4096;
        description = "Swap file size in MB.";
      };
      priority = mkOption {
        type = types.ints.positive;
        default = 1;
        description = "Swap priority.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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

    swapDevices = lib.mkIf cfg.swap.enable [
      {
        device = "/var/lib/swapfile";
        inherit (cfg.swap) size priority;
      }
    ];
  };
}
