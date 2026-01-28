{ config, ... }:
let
  wanInterface = "ens18";
  lanInterface = "ens19";
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
  };

  custom = {
    roles.headless = {
      network = {
        enable = true;
        inherit podmanInterface;
        trustedInterfaces = [
          lanInterface
          infraInterface
          wgInterface
        ];
      };
      security.enable = true;
      services.enable = true;
    };

    platform.vm = {
      hardware.enable = true;
      disks = {
        enableMain = true;
        enableStorage = true;
      };
    };

    services = {
      networking = {
        router = {
          enable = true;
          inherit
            wanInterface
            lanInterface
            infraInterface
            dmzInterface
            ;
          infraVlanId = 20;
          dmzVlanId = 88;
        };

        suricata = {
          enable = true;
          inherit
            wanInterface
            lanInterface
            infraInterface
            dmzInterface
            wgInterface
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
        geoipupdate.enable = true;
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
        prometheus.exporters = {
          kea.enable = true;
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
          interface = infraInterface;
        };
        wazuh.agent = {
          enable = true;
          interface = infraInterface;
        };
      };
    };
  };
}
