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
    vlan-ids
    ;
  inherit (helpers) getHostAddress;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.networking.router;

  mkSubnet =
    network:
    {
      id = vlan-ids.${network};
      subnet = addresses.${network}.network;
      pools = [ { pool = "${addresses.${network}.dhcp-min} - ${addresses.${network}.dhcp-max}"; } ];
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

  mkVlanNetwork =
    subnetName: interfaceName: {
      "40-${interfaceName}" = {
        matchConfig.Name = interfaceName;
        networkConfig = {
          Address = [
            "${addresses.${subnetName}.hosts.${config.networking.hostName}}/24"
            "${addresses.${subnetName}.hosts."${config.networking.hostName}-v6"}/64"
          ];
          LinkLocalAddressing = "ipv6";
        };
      };
    };

  mkRadvdInterface =
    interface: prefix: ''
      interface ${interface} {
        AdvSendAdvert on;
        prefix ${prefix} {
          AdvOnLink on;
          AdvAutonomous on;
        };
        RDNSS ${addresses.infra.vip.dns-v6} { };
      };
    '';
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
      "net.ipv4.ip_forward" = "1";
      "net.ipv6.conf.all.forwarding" = "1";
      "net.ipv4.conf.${cfg.wanInterface}.rp_filter" = "2";
      "net.ipv4.conf.${cfg.lanInterface}.rp_filter" = "2";
      "net.ipv4.conf.${cfg.infraInterface}.rp_filter" = "2";
      "net.ipv4.conf.${cfg.dmzInterface}.rp_filter" = "2";
    };

    networking = {
      useNetworkd = true;
      useDHCP = false;
      networkmanager.enable = false;

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
            allowedTCPPorts = lib.mkForce [ ];
            allowedUDPPorts = lib.mkForce [ ];
          };

          ${cfg.lanInterface} = {
            allowedTCPPorts = [ ports.dns ];
            allowedUDPPorts = [
              ports.dhcp
              ports.dns
              ports.mdns
            ];
          };

          ${cfg.infraInterface} = {
            allowedTCPPorts = [ ports.dns ];
            allowedUDPPorts = [
              ports.dhcp
              ports.dns
              ports.mdns
            ];
          };

          ${cfg.dmzInterface} = {
            allowedUDPPorts = [ ports.dhcp ];
          };
        };

        extraInputRules = /* bash */ ''
          ip6 nexthdr icmpv6 accept

          iifname "${cfg.dmzInterface}" ip daddr ${addresses.infra.vip.dns} udp dport ${toString ports.dns} accept
          iifname "${cfg.dmzInterface}" ip daddr ${addresses.infra.vip.dns} tcp dport ${toString ports.dns} accept
          iifname "${cfg.dmzInterface}" ip6 daddr ${addresses.infra.vip.dns-v6} udp dport ${toString ports.dns} accept
          iifname "${cfg.dmzInterface}" ip6 daddr ${addresses.infra.vip.dns-v6} tcp dport ${toString ports.dns} accept
        '';
      };

      nftables = {
        tables.router-flow = {
          family = "inet";
          content = /* bash */ ''
            chain forward {
              type filter hook forward priority 0; policy drop;
              ct state established,related accept

              ip6 nexthdr icmpv6 accept

              iifname "${cfg.lanInterface}" accept

              iifname "${cfg.infraInterface}" oifname "${cfg.wanInterface}" accept
              iifname "${cfg.infraInterface}" oifname "${cfg.podmanInterface}" accept
              iifname "${cfg.infraInterface}" oifname "${cfg.dmzInterface}" accept

              iifname "${cfg.dmzInterface}" oifname "${cfg.wanInterface}" accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${addresses.infra.vip.dns} udp dport ${toString ports.dns} accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${addresses.infra.vip.dns} tcp dport ${toString ports.dns} accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip6 daddr ${addresses.infra.vip.dns-v6} udp dport ${toString ports.dns} accept
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip6 daddr ${addresses.infra.vip.dns-v6} tcp dport ${toString ports.dns} accept
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
                nixosConfigurations.vm-monitor.config.custom.services.security.trivy.server.enable
                /* bash */ ''
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${getHostAddress "vm-monitor"} tcp dport ${toString ports.trivy} accept
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

    systemd.network = {
      enable = true;

      netdevs = {
        "20-${cfg.infraInterface}" = {
          netdevConfig = {
            Name = cfg.infraInterface;
            Kind = "vlan";
          };
          vlanConfig.Id = vlan-ids.infra;
        };

        "20-${cfg.dmzInterface}" = {
          netdevConfig = {
            Name = cfg.dmzInterface;
            Kind = "vlan";
          };
          vlanConfig.Id = vlan-ids.dmz;
        };
      };

      networks = lib.foldl' lib.recursiveUpdate { } [
        {
          "30-${cfg.lanInterface}" = {
            matchConfig.Name = cfg.lanInterface;
            vlan = [
              cfg.infraInterface
              cfg.dmzInterface
            ];
            networkConfig = {
              Address = [
                "${addresses.home.hosts.${config.networking.hostName}}/24"
                "${addresses.home.hosts."${config.networking.hostName}-v6"}/64"
              ];
              LinkLocalAddressing = "ipv6";
            };
          };

          "40-${cfg.wanInterface}" = {
            matchConfig.Name = cfg.wanInterface;
            networkConfig.DHCP = "yes";
          };
        }
        (mkVlanNetwork "infra" cfg.infraInterface)
        (mkVlanNetwork "dmz" cfg.dmzInterface)
      ];
    };

    services = {
      avahi = {
        enable = true;
        reflector = true;
        ipv6 = true;
        nssmdns4 = true;
        nssmdns6 = true;

        allowInterfaces = [
          cfg.lanInterface
          cfg.infraInterface
        ];
      };

      kea = {
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

      radvd = {
        enable = true;
        config = lib.concatStringsSep "\n" [
          (mkRadvdInterface cfg.lanInterface addresses.home.network-v6)
          (mkRadvdInterface cfg.infraInterface addresses.infra.network-v6)
          (mkRadvdInterface cfg.dmzInterface addresses.dmz.network-v6)
        ];
      };
    };
  };
}
