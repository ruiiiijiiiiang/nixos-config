{
  config,
  consts,
  inputs,
  ...
}:
let
  inherit (consts) addresses hardware vlan-ids;
  inherit (inputs.self) nixosConfigurations;
  wanInterface = "wan0";
  lanInterface = "lan0";
  podmanInterface = "podman0";
  infraInterface = "infra0";
  dmzInterface = "dmz0";
  wgInterface = "wg0";
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-network";

  age.secrets = {
    wireguard-server-private-key.file = ../../secrets/wireguard/server-private-key.age;
    wireguard-framework-preshared-key.file = ../../secrets/wireguard/framework-preshared-key.age;
    wireguard-iphone-16-preshared-key.file = ../../secrets/wireguard/iphone-16-preshared-key.age;
    wireguard-iphone-17-preshared-key.file = ../../secrets/wireguard/iphone-17-preshared-key.age;
    wireguard-github-action-preshared-key.file = ../../secrets/wireguard/github-action-preshared-key.age;
  };

  custom = {
    platforms.vm = {
      kernel = {
        enable = true;
        hardwarePassthrough = "nic";
      };

      libvirt = {
        enable = true;
        cpu = 4;
        memory = 2;
        autoStart = true;
        extraConfigs = {
          devices = {
            interface = [
              {
                type = "bridge";
                mac = {
                  address = hardware.macs.vm-network;
                };
                source = {
                  bridge =
                    nixosConfigurations.hypervisor.config.custom.roles.headless.hypervisor.networking.lanBridge;
                };
                vlan = {
                  trunk = true;
                  tag = [
                    {
                      id = vlan-ids.home;
                      nativeMode = "untagged";
                    }
                    { id = vlan-ids.infra; }
                    { id = vlan-ids.dmz; }
                  ];
                };
                model = {
                  type = "virtio";
                };
              }
            ];
          };
        };
      };

      disks.enable = true;

      networking = {
        enable = true;
        inherit wanInterface lanInterface;
      };
    };

    roles.headless = {
      networking = {
        enable = true;
        trustedInterfaces = [
          lanInterface
          infraInterface
          wgInterface
        ];
      };
      security.enable = true;
      services.enable = true;
    };

    services = {
      infra.podman.enable = true;

      networking = {
        router = {
          enable = true;
          inherit
            wanInterface
            lanInterface
            podmanInterface
            infraInterface
            dmzInterface
            ;
        };

        wireguard.server = {
          enable = true;
          inherit
            wanInterface
            lanInterface
            infraInterface
            dmzInterface
            wgInterface
            ;
          privateKeyFile = config.age.secrets.wireguard-server-private-key.path;
          peers = [
            {
              hostName = "framework";
              presharedKeyFile = config.age.secrets.wireguard-framework-preshared-key.path;
            }
            {
              hostName = "iphone-16";
              presharedKeyFile = config.age.secrets.wireguard-iphone-16-preshared-key.path;
            }
            {
              hostName = "iphone-17";
              presharedKeyFile = config.age.secrets.wireguard-iphone-17-preshared-key.path;
            }
            {
              hostName = "github-action";
              presharedKeyFile = config.age.secrets.wireguard-github-action-preshared-key.path;
            }
          ];
        };

        dns = {
          enable = true;
          interface = infraInterface;
          vrrp = {
            enable = true;
            state = "MASTER";
            priority = 100;
          };
        };
        dyndns.enable = true;
        cloudflared.enable = true;
        nginx.enable = true;
      };

      observability = {
        beszel.agent = {
          enable = true;
          interface = infraInterface;
        };
        dockhand.agent = {
          enable = true;
          interface = infraInterface;
        };
        loki.agent = {
          enable = true;
          serverAddress = addresses.infra.hosts.vm-monitor;
        };
        prometheus.exporters = {
          kea.enable = true;
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
          wireguard.enable = true;
          interface = infraInterface;
        };
      };

      security = {
        fail2ban.enable = true;
        wazuh.agent = {
          enable = true;
          serverAddress = addresses.infra.hosts.vm-monitor;
          interface = infraInterface;
        };
      };
    };
  };
}
