{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.platform.pi.network;
in
{
  options.custom.platform.pi.network = with lib; {
    enable = mkEnableOption "Raspberry Pi 4 networking config";
    lanInterface = mkOption {
      type = types.str;
      default = "end0";
      description = "Ethernet interface";
    };
    wlanInterface = mkOption {
      type = types.str;
      default = "wlan0";
      description = "Wifi interface";
    };
    vlanId = mkOption {
      type = types.int;
      default = 20;
      description = "VLAN tag ID";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      useDHCP = false;

      interfaces = {
        ${cfg.lanInterface} = {
          useDHCP = false;
        };
        ${cfg.wlanInterface} = {
          useDHCP = false;
        };
        "${cfg.lanInterface}.${toString cfg.vlanId}" = {
          useDHCP = true;
        };
      };

      vlans."${cfg.lanInterface}.${toString cfg.vlanId}" = {
        interface = cfg.lanInterface;
        id = cfg.vlanId;
      };

      networkmanager.unmanaged = [
        cfg.lanInterface
        cfg.wlanInterface
      ];
    };
  };
}
