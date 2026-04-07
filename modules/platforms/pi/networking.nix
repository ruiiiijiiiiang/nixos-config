{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) vlan-ids;
  cfg = config.custom.platforms.pi.networking;
in
{
  options.custom.platforms.pi.networking = with lib; {
    enable = mkEnableOption "Enable Raspberry Pi 4 networking";
    lanInterface = mkOption {
      type = types.str;
      default = "end0";
      description = "Ethernet interface name.";
    };
    wlanInterface = mkOption {
      type = types.str;
      default = "wlan0";
      description = "WiFi interface name.";
    };
    vlanId = mkOption {
      type = types.ints.positive;
      default = vlan-ids.infra;
      description = "VLAN ID for the LAN interface.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.elem cfg.vlanId (lib.attrValues vlan-ids);
        message = "Pi VLAN ID must exist in consts.vlan-ids.";
      }
      {
        assertion = cfg.lanInterface != cfg.wlanInterface;
        message = "Pi LAN and WLAN interfaces must be different.";
      }
    ];

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
