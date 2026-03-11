{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) ssh;
  inherit (consts) username hardware;
  cfg = config.custom.platforms.vm.networking;
in
{
  options.custom.platforms.vm.networking = with lib; {
    enable = mkEnableOption "Enable VM networking config";
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN interface name.";
    };
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WAN interface name.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      usePredictableInterfaceNames = false;
    };

    systemd.network = {
      links = {
        "10-lan" = lib.mkIf (cfg.lanInterface != null) {
          matchConfig.MACAddress = hardware.macs.${config.networking.hostName};
          linkConfig.Name = cfg.lanInterface;
        };

        "11-wan" = lib.mkIf (cfg.wanInterface != null) {
          matchConfig.MACAddress = hardware.macs.wan;
          linkConfig.Name = cfg.wanInterface;
        };
      };
    };

    users.users.${username}.openssh.authorizedKeys.keys = ssh.hypervisor;
    users.users.root.openssh.authorizedKeys.keys = ssh.hypervisor;
  };
}
