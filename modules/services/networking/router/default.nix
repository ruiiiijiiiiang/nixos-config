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
      description = "Interface connecting to the WAN";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface connecting to the LAN";
    };

    dmz = {
      enable = mkEnableOption "DMZ VLAN";
      vlanId = mkOption {
        type = types.int;
        default = 88;
        description = "VLAN tag ID for the DMZ";
      };
      interface = mkOption {
        type = types.str;
        default = "dmz0";
        description = "Virtual interface name for the DMZ";
      };
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

        ${cfg.dmz.interface} = lib.mkIf cfg.dmz.enable {
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
        internalInterfaces = [ cfg.lanInterface ] ++ (lib.optional cfg.dmz.enable cfg.dmz.interface);
      };

      firewall = {
        enable = true;
        interfaces = {
          ${cfg.wanInterface} = {
            allowedTCPPorts = [ ];
            allowedUDPPorts = [ ];
          };

          ${cfg.lanInterface} = {
            allowedUDPPorts = [ ports.dhcp ];
          };

          ${cfg.dmz.interface} = lib.mkIf cfg.dmz.enable {
            allowedUDPPorts = [
              ports.dhcp
              ports.dns
            ];
            allowedTCPPorts = [ ports.dns ];
          };
        };
      };

      vlans.${cfg.dmz.interface} = lib.mkIf cfg.dmz.enable {
        id = cfg.dmz.vlanId;
        interface = cfg.lanInterface;
      };

      nftables = {
        enable = true;
        tables.router-flow = {
          family = "ip";
          content = ''
            chain forward {
              type filter hook forward priority 0; policy accept;

              # Allow return traffic
              ct state established,related accept

              # Conditional DMZ Rules inserted via string interpolation
              ${lib.optionalString cfg.dmz.enable ''
                # Allow LAN -> DMZ
                iifname "${cfg.lanInterface}" oifname "${cfg.dmz.interface}" accept

                # Allow DMZ -> LAN (DNS Only)
                iifname "${cfg.dmz.interface}" oifname "${cfg.lanInterface}" ip daddr ${addresses.home.vip.dns} udp dport ${toString ports.dns} accept
                iifname "${cfg.dmz.interface}" oifname "${cfg.lanInterface}" ip daddr ${addresses.home.vip.dns} tcp dport ${toString ports.dns} accept

                # Drop other DMZ -> LAN
                iifname "${cfg.dmz.interface}" oifname "${cfg.lanInterface}" drop
              ''}
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
            interfaces = [ cfg.lanInterface ] ++ (lib.optional cfg.dmz.enable cfg.dmz.interface);
          };
          valid-lifetime = 86400;
          subnet4 = [
            {
              id = 1;
              reservations = getReservations "home";
              subnet = addresses.home.network;
              pools = [ { pool = "${addresses.home.dhcp-min} - ${addresses.home.dhcp-max}"; } ];
              option-data = [
                {
                  name = "routers";
                  data = addresses.home.hosts.vm-network;
                }
                {
                  name = "domain-name-servers";
                  data = addresses.home.vip.dns;
                }
              ];
            }
          ]
          ++ (lib.optionals cfg.dmz.enable [
            {
              id = cfg.dmz.vlanId;
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
                  data = addresses.home.vip.dns;
                }
              ];
            }
          ]);
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
