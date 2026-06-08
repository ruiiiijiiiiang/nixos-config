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
  cfg = config.custom.platforms.pi.networking;
  vlanInterface = "${cfg.lanInterface}.${toString cfg.vlanId}";
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
        "10-${cfg.lanInterface}" = {
          matchConfig.Name = cfg.lanInterface;
          networkConfig = {
            VLAN = [ vlanInterface ];
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "carrier";
        };

        "20-${vlanInterface}" = {
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

        "30-${cfg.wlanInterface}" = lib.mkIf (cfg.wlanInterface != null) {
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

    services.avahi = {
      enable = true;
      ipv6 = true;
      nssmdns4 = true;
      nssmdns6 = true;
    };
  };
}
