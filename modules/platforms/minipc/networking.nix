{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) domain addresses vlan-ids;
  cfg = config.custom.platforms.minipc.networking;
  vlanInterface = "${cfg.lanBridge}.${toString cfg.vlanId}";
in
{
  options.custom.platforms.minipc.networking = with lib; {
    enable = mkEnableOption "Enable minipc networking";
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN interface name.";
    };
    wlanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WLAN interface name.";
    };
    lanBridge = mkOption {
      type = types.str;
      default = "br0";
      description = "LAN bridge name.";
    };
    vlanId = mkOption {
      type = types.ints.positive;
      default = vlan-ids.infra;
      description = "VLAN ID for infra.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      useNetworkd = true;
      useDHCP = false;
      networkmanager.enable = false;

      wireless.iwd = lib.mkIf (cfg.wlanInterface != null) {
        enable = true;
        settings = {
          Settings = {
            AutoConnect = false;
          };
          Network = {
            RoutePriorityOffset = 2048;
          };
        };
      };
    };

    systemd.network = {
      enable = true;

      netdevs = {
        "10-${cfg.lanBridge}" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "${cfg.lanBridge}";
          };
          bridgeConfig = {
            VLANFiltering = true;
          };
        };

        "20-${vlanInterface}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = vlanInterface;
          };
          vlanConfig = {
            Id = cfg.vlanId;
          };
        };
      };

      networks = {
        "10-${cfg.lanInterface}" = lib.mkIf (cfg.lanInterface != null) {
          matchConfig.Name = cfg.lanInterface;
          networkConfig = {
            Bridge = cfg.lanBridge;
            LinkLocalAddressing = "no";
          };
          bridgeVLANs = [
            {
              VLAN = vlan-ids.home;
              PVID = vlan-ids.home;
              EgressUntagged = true;
            }
            { VLAN = vlan-ids.infra; }
            { VLAN = vlan-ids.dmz; }
          ];
          linkConfig.RequiredForOnline = "enslaved";
        };

        "20-${cfg.lanBridge}" = {
          matchConfig.Name = cfg.lanBridge;
          networkConfig = {
            VLAN = [ vlanInterface ];
            LinkLocalAddressing = "no";
          };
          bridgeVLANs = [
            { VLAN = vlan-ids.infra; }
          ];
          linkConfig.RequiredForOnline = "carrier";
        };

        "30-${vlanInterface}" = {
          matchConfig.Name = vlanInterface;
          networkConfig = {
            Address = "${addresses.infra.hosts.hypervisor}/24";
            Gateway = addresses.infra.hosts.vm-network;
            DNS = [ addresses.infra.vip.dns ];
            Domains = [ domain ];
          };
          linkConfig.RequiredForOnline = "routable";
        };

        "40-${cfg.wlanInterface}" = lib.mkIf (cfg.wlanInterface != null) {
          matchConfig.Name = cfg.wlanInterface;
          networkConfig = {
            Address = "${addresses.home.hosts.hypervisor-wifi}/24";
            DHCP = "yes";
            IgnoreCarrierLoss = "3s";
          };
          dhcpV4Config = {
            RouteMetric = 2048;
          };
          dhcpV6Config = {
            RouteMetric = 2048;
          };
          linkConfig.RequiredForOnline = "no";
        };
      };
    };
  };
}
