{
  config,
  consts,
  inputs,
  ...
}:
let
  inherit (consts) addresses hardware;
  inherit (inputs.self) nixosConfigurations;
  wanInterface = "ens18";
  lanInterface = "ens19";
  podmanInterface = "podman0";
  infraInterface = "infra0";
  dmzInterface = "dmz0";
  wgInterface = "wg0";
  wanMac = "bc:24:11:97:f8:42";
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
      kernel.enable = true;

      libvirt = {
        enable = true;
        config = {
          vcpu = {
            count = 4;
          };
          memory = {
            count = 4;
          };
          currentMemory = {
            count = 2;
          };
          devices =
            let
              inherit (nixosConfigurations.hypervisor.config.custom.roles.headless.hypervisor) networking;
            in
            {
              interface = [
                {
                  type = "bridge";
                  mac = {
                    address = wanMac;
                  };
                  source = {
                    bridge = networking.wanBridge;
                  };
                  model = {
                    type = "virtio";
                  };
                }
                {
                  type = "bridge";
                  mac = {
                    address = hardware.macs.vm-network;
                  };
                  source = {
                    bridge = networking.lanBridge;
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
      server = {
        podman.enable = true;
      };
    };

    services = {
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
          interface = infraInterface;
        };
      };
    };
  };
}
