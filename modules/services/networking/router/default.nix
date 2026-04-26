{
  config,
  consts,
  lib,
  inputs,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    ports
    hardware
    vlan-ids
    ;
  inherit (helpers) getHostAddress;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.networking.router;

  mkSubnet =
    network:
    let
      inherit (addresses.${network}) hosts;
      reservations = lib.map (hostname: {
        hw-address = hardware.macs.${hostname};
        ip-address = hosts.${hostname};
        inherit hostname;
      }) (lib.filter (hostname: lib.hasAttr hostname hosts) (lib.attrNames hardware.macs));
    in
    {
      id = vlan-ids.${network};
      subnet = addresses.${network}.network;
      pools = [ { pool = "${addresses.${network}.dhcp-min} - ${addresses.${network}.dhcp-max}"; } ];
      inherit reservations;
      option-data = [
        {
          name = "routers";
          data = addresses.${network}.hosts.${config.networking.hostName};
        }
        {
          name = "domain-name-servers";
          data = addresses.infra.vip.dns;
        }
      ];
    };
in
{
  options.custom.services.networking.router = with lib; {
    enable = mkEnableOption "Enable router role";
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WAN interface name.";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN interface name.";
    };
    podmanInterface = mkOption {
      type = types.str;
      default = "podman0";
      description = "Podman interface name.";
    };
    infraInterface = mkOption {
      type = types.str;
      default = "infra0";
      description = "Infra VLAN interface name.";
    };
    dmzInterface = mkOption {
      type = types.str;
      default = "dmz0";
      description = "DMZ VLAN interface name.";
    };
    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard interface name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "Router requires WAN and LAN interfaces.";
      }
      {
        assertion =
          lib.length (
            lib.unique [
              cfg.wanInterface
              cfg.lanInterface
              cfg.podmanInterface
              cfg.infraInterface
              cfg.dmzInterface
            ]
          ) == 5;
        message = "Router interface names must all be distinct.";
      }
      {
        assertion =
          lib.hasAttr config.networking.hostName addresses.home.hosts
          && lib.hasAttr config.networking.hostName addresses.infra.hosts
          && lib.hasAttr config.networking.hostName addresses.dmz.hosts;
        message = "Router hostName must exist in addresses.home/infra/dmz host maps.";
      }
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
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

        extraInputRules = /* bash */ ''
          iifname "${cfg.dmzInterface}" ip daddr ${addresses.infra.vip.dns} udp dport ${toString ports.dns} accept
          iifname "${cfg.dmzInterface}" ip daddr ${addresses.infra.vip.dns} tcp dport ${toString ports.dns} accept
        '';
      };

      vlans = {
        ${cfg.infraInterface} = {
          id = vlan-ids.infra;
          interface = cfg.lanInterface;
        };

        ${cfg.dmzInterface} = {
          id = vlan-ids.dmz;
          interface = cfg.lanInterface;
        };
      };

      nftables = {
        tables.router-flow = {
          family = "inet";
          content = /* bash */ ''
            chain forward {
              type filter hook forward priority 0; policy drop;
              ct state established,related accept

              iifname "${cfg.lanInterface}" accept

              iifname "${cfg.infraInterface}" oifname "${cfg.wanInterface}" accept
              iifname "${cfg.infraInterface}" oifname "${cfg.podmanInterface}" accept
              iifname "${cfg.infraInterface}" oifname "${cfg.dmzInterface}" accept

              ${lib.optionalString nixosConfigurations.pi.config.custom.services.apps.tools.homeassistant.enable
                /* bash */ ''
                  iifname "${cfg.infraInterface}" oifname "${cfg.lanInterface}" ether saddr ${hardware.macs.pi} udp dport { 5353, 5540 } accept
                  iifname "${cfg.infraInterface}" oifname "${cfg.lanInterface}" ether saddr ${hardware.macs.pi} tcp dport 5540 accept
                ''
              }

              iifname "${cfg.dmzInterface}" oifname "${cfg.wanInterface}" accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${addresses.infra.vip.dns} udp dport ${toString ports.dns} accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${addresses.infra.vip.dns} tcp dport ${toString ports.dns} accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${getHostAddress "vm-app"} tcp dport { ${toString ports.http}, ${toString ports.https} } accept

              ${lib.optionalString
                nixosConfigurations.vm-monitor.config.custom.services.observability.loki.server.enable
                /* bash */ ''
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${getHostAddress "vm-monitor"} tcp dport ${toString ports.loki.server} accept
                ''
              }

              ${lib.optionalString
                nixosConfigurations.vm-monitor.config.custom.services.security.wazuh.server.enable
                /* bash */ ''
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${getHostAddress "vm-monitor"} tcp dport { ${toString ports.wazuh.agent.connection}, ${toString ports.wazuh.agent.enrollment} } accept
                ''
              }

              ${lib.optionalString
                nixosConfigurations.vm-network.config.custom.services.networking.wireguard.server.enable
                /* bash */ ''
                  iifname "${cfg.wgInterface}" oifname "${cfg.lanInterface}" accept
                  iifname "${cfg.wgInterface}" oifname "${cfg.infraInterface}" accept
                  iifname "${cfg.wgInterface}" oifname "${cfg.dmzInterface}" accept
                ''
              }
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
          subnet4 = map mkSubnet [
            "home"
            "infra"
            "dmz"
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
