{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports macs;
  cfg = config.custom.services.networking.router;

  getReservations =
    network:
    let
      inherit (addresses.${network}) hosts;
    in
    builtins.map (hostname: {
      hw-address = macs.${hostname};
      ip-address = hosts.${hostname};
      inherit hostname;
    }) (builtins.filter (hostname: builtins.hasAttr hostname hosts) (builtins.attrNames macs));
in
{
  options.custom.services.networking.router = with lib; {
    enable = mkEnableOption "Network router";
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for WAN";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for LAN";
    };
    podmanInterface = mkOption {
      type = types.str;
      default = "podman0";
      description = "Interface for podman";
    };
    infraVlanId = mkOption {
      type = types.int;
      default = 20;
      description = "VLAN tag ID for infra";
    };
    infraInterface = mkOption {
      type = types.str;
      default = "infra0";
      description = "Interface for infra VLAN";
    };
    dmzVlanId = mkOption {
      type = types.int;
      default = 88;
      description = "VLAN tag ID for DMZ";
    };
    dmzInterface = mkOption {
      type = types.str;
      default = "dmz0";
      description = "Interface for DMZ VLAN";
    };
    extraForwardRules = mkOption {
      type = types.lines;
      default = "";
      description = "Extra rules to append to the router forward chain.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "Router is enabled but required interfaces are missing.";
      }
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
    };

    networking = {
      networkmanager.enable = false;

      interfaces = {
        ${cfg.wanInterface}.useDHCP = true;

        ${cfg.lanInterface} = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = addresses.home.hosts.${config.networking.hostName};
              prefixLength = 24;
            }
          ];
        };

        ${cfg.infraInterface} = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = addresses.infra.hosts.${config.networking.hostName};
              prefixLength = 24;
            }
          ];
        };

        ${cfg.dmzInterface} = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = addresses.dmz.hosts.${config.networking.hostName};
              prefixLength = 24;
            }
          ];
        };
      };

      nat = {
        enable = true;
        externalInterface = cfg.wanInterface;
        internalInterfaces = [
          cfg.lanInterface
          cfg.infraInterface
          cfg.dmzInterface
        ];
      };

      firewall = {
        enable = true;
        interfaces = {
          ${cfg.wanInterface} = {
            allowedTCPPorts = [ ];
            allowedUDPPorts = [ ];
          };

          ${cfg.lanInterface} = {
            allowedTCPPorts = [ ports.dns ];
            allowedUDPPorts = [
              ports.dhcp
              ports.dns
            ];
          };

          ${cfg.infraInterface} = {
            allowedTCPPorts = [ ports.dns ];
            allowedUDPPorts = [
              ports.dhcp
              ports.dns
            ];
          };

          ${cfg.dmzInterface} = {
            allowedUDPPorts = [ ports.dhcp ];
          };
        };

        extraInputRules = ''
          iifname "${cfg.dmzInterface}" ip daddr ${addresses.infra.vip.dns} udp dport ${toString ports.dns} accept
          iifname "${cfg.dmzInterface}" ip daddr ${addresses.infra.vip.dns} tcp dport ${toString ports.dns} accept
        '';
      };

      vlans = {
        ${cfg.infraInterface} = {
          id = cfg.infraVlanId;
          interface = cfg.lanInterface;
        };

        ${cfg.dmzInterface} = {
          id = cfg.dmzVlanId;
          interface = cfg.lanInterface;
        };
      };

      nftables = {
        enable = true;
        tables.router-flow = {
          family = "ip";
          content = ''
            chain forward {
              type filter hook forward priority 0; policy drop;
              ct state established,related accept

              iifname "${cfg.lanInterface}" accept

              iifname "${cfg.infraInterface}" oifname "${cfg.wanInterface}" accept
              iifname "${cfg.infraInterface}" oifname "${cfg.podmanInterface}" accept
              iifname "${cfg.infraInterface}" oifname "${cfg.dmzInterface}" accept

              iifname "${cfg.dmzInterface}" oifname "${cfg.wanInterface}" accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${addresses.infra.vip.dns} udp dport ${toString ports.dns} accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${addresses.infra.vip.dns} tcp dport ${toString ports.dns} accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${addresses.infra.hosts.vm-app} tcp dport { ${toString ports.http}, ${toString ports.https} } accept

              ${cfg.extraForwardRules}
            }
          '';
        };
      };
    };

    services.kea = {
      dhcp4 = {
        enable = true;
        settings = {
          interfaces-config = {
            interfaces = [
              cfg.lanInterface
              cfg.infraInterface
              cfg.dmzInterface
            ];
          };
          valid-lifetime = 86400;
          subnet4 = [
            {
              id = 2;
              subnet = addresses.home.network;
              pools = [ { pool = "${addresses.home.dhcp-min} - ${addresses.home.dhcp-max}"; } ];
              reservations = getReservations "home";
              option-data = [
                {
                  name = "routers";
                  data = addresses.home.hosts.${config.networking.hostName};
                }
                {
                  name = "domain-name-servers";
                  data = addresses.infra.vip.dns;
                }
              ];
            }

            {
              id = cfg.infraVlanId;
              subnet = addresses.infra.network;
              pools = [ { pool = "${addresses.infra.dhcp-min} - ${addresses.infra.dhcp-max}"; } ];
              reservations = getReservations "infra";
              option-data = [
                {
                  name = "routers";
                  data = addresses.infra.hosts.${config.networking.hostName};
                }
                {
                  name = "domain-name-servers";
                  data = addresses.infra.vip.dns;
                }
              ];
            }

            {
              id = cfg.dmzVlanId;
              subnet = addresses.dmz.network;
              pools = [ { pool = "${addresses.dmz.dhcp-min} - ${addresses.dmz.dhcp-max}"; } ];
              reservations = getReservations "dmz";
              option-data = [
                {
                  name = "routers";
                  data = addresses.dmz.hosts.${config.networking.hostName};
                }
                {
                  name = "domain-name-servers";
                  data = addresses.infra.vip.dns;
                }
              ];
            }
          ];

          control-socket = {
            socket-type = "unix";
            socket-name = "/run/kea/kea-dhcp4.socket";
          };
        };
      };

      ctrl-agent = lib.mkIf config.custom.services.observability.prometheus.exporters.kea.enable {
        enable = true;
        settings = {
          http-host = addresses.localhost;
          http-port = ports.kea.ctrl-agent;
          control-sockets = {
            dhcp4 = {
              socket-type = "unix";
              socket-name = "/run/kea/kea-dhcp4.socket";
            };
          };
        };
      };
    };
  };
}
