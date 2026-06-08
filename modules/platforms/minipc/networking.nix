{
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (consts) domain addresses vlan-ids;
  inherit (helpers) getHostAddress getGatewayAddress getHostSubnet;
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
    assertions = [
      {
        assertion = lib.elem cfg.vlanId (lib.attrValues vlan-ids);
        message = "VLAN ID must exist in consts.vlan-ids.";
      }
      {
        assertion = cfg.lanInterface != cfg.wlanInterface;
        message = "LAN and WLAN interfaces must be different.";
      }
    ];

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
            Address = [
              "${getHostAddress hostName}/24"
              "${
                getHostAddress {
                  inherit hostName;
                  isV6 = true;
                }
              }/64"
            ];
            Gateway = [
              (getGatewayAddress hostName)
              (getGatewayAddress {
                inherit hostName;
                isV6 = true;
              })
            ];
            DNS = [
              addresses.infra.vip.dns
              addresses.infra.vip.dns-v6
            ];
            Domains = [ domain ];
            IPv4ReversePathFilter = "loose";
          };
          routingPolicyRules = [
            {
              From = getHostAddress hostName;
              Table = 20;
            }
            {
              From = getHostAddress {
                inherit hostName;
                isV6 = true;
              };
              Table = 20;
            }
          ];
          routes = [
            {
              Destination = getHostSubnet hostName;
              Scope = "link";
              Table = 20;
            }
            {
              Destination = getHostSubnet {
                inherit hostName;
                isV6 = true;
              };
              Scope = "link";
              Table = 20;
            }
            {
              Gateway = getGatewayAddress hostName;
              Table = 20;
            }
            {
              Gateway = getGatewayAddress {
                inherit hostName;
                isV6 = true;
              };
              Table = 20;
            }
          ];
          linkConfig.RequiredForOnline = "routable";
        };

        "40-${cfg.wlanInterface}" = lib.mkIf (cfg.wlanInterface != null) {
          matchConfig.Name = cfg.wlanInterface;
          networkConfig = {
            Address = [
              "${getHostAddress "${hostName}-wifi"}/24"
              "${
                getHostAddress {
                  hostName = "${hostName}-wifi";
                  isV6 = true;
                }
              }/64"
            ];
            DHCP = "ipv4";
            IgnoreCarrierLoss = "3s";
            IPv4ReversePathFilter = "loose";
          };
          routingPolicyRules = [
            {
              From = getHostAddress "${hostName}-wifi";
              Table = 2;
            }
            {
              From = getHostAddress {
                hostName = "${hostName}-wifi";
                isV6 = true;
              };
              Table = 2;
            }
          ];
          routes = [
            {
              Destination = getHostSubnet "${hostName}-wifi";
              Scope = "link";
              Table = 2;
            }
            {
              Destination = getHostSubnet {
                hostName = "${hostName}-wifi";
                isV6 = true;
              };
              Scope = "link";
              Table = 2;
            }
            {
              Gateway = getGatewayAddress "${hostName}-wifi";
              Table = 2;
            }
            {
              Gateway = getGatewayAddress {
                hostName = "${hostName}-wifi";
                isV6 = true;
              };
              Table = 2;
            }
          ];
          dhcpV4Config = {
            RouteMetric = 2048;
          };
          ipv6AcceptRAConfig = {
            RouteMetric = 2048;
          };
          linkConfig.RequiredForOnline = "no";
        };
      };
    };
  };
}
