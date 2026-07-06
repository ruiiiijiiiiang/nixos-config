{
  config,
  consts,
  helpers,
  inputs,
  lib,
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
    { network }:
    {
      id = vlan-ids.${network};
      subnet = addresses.${network}.network;
      pools = [ { pool = "${addresses.${network}.dhcp-min} - ${addresses.${network}.dhcp-max}"; } ];
      option-data = [
        {
          name = "routers";
          data = getHostAddress {
            inherit (config.networking) hostName;
            inherit network;
          };
        }
        {
          name = "domain-name-servers";
          data = addresses.infra.vip.dns;
        }
      ];
    };

  mkVlanNetwork =
    { subnetName, interfaceName }:
    {
      "40-${interfaceName}" = {
        matchConfig.Name = interfaceName;
        networkConfig = {
          Address = [
            "${
              getHostAddress {
                inherit (config.networking) hostName;
                network = subnetName;
              }
            }/24"
            "${
              getHostAddress {
                inherit (config.networking) hostName;
                network = subnetName;
                isV6 = true;
              }
            }/64"
          ];
          LinkLocalAddressing = "ipv6";
        };
      };
    };

  mkRadvdInterface =
    {
      interface,
      prefix,
      enablePD,
    }:
    /* bash */ ''
      interface ${interface} {
        AdvSendAdvert on;
        prefix ${prefix} {
          AdvOnLink on;
          AdvAutonomous on;
        };
        ${lib.optionalString enablePD /* bash */ ''
          prefix ::/64 {
            AdvOnLink on;
            AdvAutonomous on;
          };
        ''}
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
          lib.hasAttrByPath [ "home" "hosts" config.networking.hostName ] addresses
          && lib.hasAttrByPath [ "infra" "hosts" config.networking.hostName ] addresses
          && lib.hasAttrByPath [ "dmz" "hosts" config.networking.hostName ] addresses;
        message = "Router hostName must exist in addresses.home/infra/dmz host maps.";
      }
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = "1";
      "net.ipv6.conf.all.forwarding" = "1";

      "net.ipv4.conf.all.arp_ignore" = "1";
      "net.ipv4.conf.all.arp_announce" = "2";

      "net.ipv4.conf.${cfg.wanInterface}.rp_filter" = "2";
      "net.ipv4.conf.${cfg.lanInterface}.rp_filter" = "2";
      "net.ipv4.conf.${cfg.infraInterface}.rp_filter" = "2";
      "net.ipv4.conf.${cfg.dmzInterface}.rp_filter" = "2";

      "net.ipv6.conf.${cfg.wanInterface}.accept_ra" = "2";
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
        ]
        ++
          lib.optionals
            nixosConfigurations.vm-network.config.custom.services.networking.wireguard.server.enable
            [
              cfg.wgInterface
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
              iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip6 daddr ${
                getHostAddress {
                  hostName = "vm-app";
                  isV6 = true;
                }
              } tcp dport { ${toString ports.http}, ${toString ports.https} } accept

              ${lib.optionalString
                nixosConfigurations.vm-monitor.config.custom.services.observability.loki.server.enable
                /* bash */ ''
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${getHostAddress "vm-monitor"} tcp dport ${toString ports.loki.server} accept
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip6 daddr ${
                    getHostAddress {
                      hostName = "vm-monitor";
                      isV6 = true;
                    }
                  } tcp dport ${toString ports.loki.server} accept
                ''
              }

              ${lib.optionalString
                nixosConfigurations.vm-monitor.config.custom.services.security.wazuh.server.enable
                /* bash */ ''
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${getHostAddress "vm-monitor"} tcp dport { ${toString ports.wazuh.agent.connection}, ${toString ports.wazuh.agent.enrollment} } accept
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip6 daddr ${
                    getHostAddress {
                      hostName = "vm-monitor";
                      isV6 = true;
                    }
                  } tcp dport { ${toString ports.wazuh.agent.connection}, ${toString ports.wazuh.agent.enrollment} } accept
                ''
              }

              ${lib.optionalString
                nixosConfigurations.vm-monitor.config.custom.services.security.trivy.server.enable
                /* bash */ ''
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip daddr ${getHostAddress "vm-monitor"} tcp dport ${toString ports.trivy} accept
                  iifname "${cfg.dmzInterface}" oifname "${cfg.infraInterface}" ip6 daddr ${
                    getHostAddress {
                      hostName = "vm-monitor";
                      isV6 = true;
                    }
                  } tcp dport ${toString ports.trivy} accept
                ''
              }

              ${lib.optionalString
                nixosConfigurations.vm-network.config.custom.services.networking.wireguard.server.enable
                /* bash */ ''
                  iifname "${cfg.wgInterface}" oifname "${cfg.lanInterface}" accept
                  iifname "${cfg.wgInterface}" oifname "${cfg.infraInterface}" accept
                  iifname "${cfg.wgInterface}" oifname "${cfg.dmzInterface}" accept
                  iifname "${cfg.wgInterface}" oifname "${cfg.wanInterface}" accept
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
                "${
                  getHostAddress {
                    inherit (config.networking) hostName;
                    network = "home";
                  }
                }/24"
                "${
                  getHostAddress {
                    inherit (config.networking) hostName;
                    network = "home";
                    isV6 = true;
                  }
                }/64"
              ];
              LinkLocalAddressing = "ipv6";
              DHCPPrefixDelegation = "yes";
            };
            dhcpPrefixDelegationConfig = {
              UplinkInterface = cfg.wanInterface;
              SubnetId = 0;
              Announce = "yes";
            };
          };

          "40-${cfg.wanInterface}" = {
            matchConfig.Name = cfg.wanInterface;
            networkConfig = {
              DHCP = "yes";
              IPv6AcceptRA = "yes";
            };
            dhcpV6Config = {
              PrefixDelegationHint = "::/60";
            };
          };
        }
        (mkVlanNetwork {
          subnetName = "infra";
          interfaceName = cfg.infraInterface;
        })
        (mkVlanNetwork {
          subnetName = "dmz";
          interfaceName = cfg.dmzInterface;
        })
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
            subnet4 = map (network: mkSubnet { inherit network; }) [
              "home"
              "infra"
              "dmz"
            ];
          };
        };
      };

      radvd = {
        enable = true;
        config = lib.concatStringsSep "\n" [
          (mkRadvdInterface {
            interface = cfg.lanInterface;
            prefix = addresses.home.network-v6;
            enablePD = true;
          })
          (mkRadvdInterface {
            interface = cfg.infraInterface;
            prefix = addresses.infra.network-v6;
            enablePD = false;
          })
          (mkRadvdInterface {
            interface = cfg.dmzInterface;
            prefix = addresses.dmz.network-v6;
            enablePD = false;
          })
        ];
      };
    };
  };
}
