{ config, ... }:
let
  wanInterface = "ens18";
  lanInterface = "ens19";
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
      network.enable = true;
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
          inherit wanInterface;
          inherit lanInterface;
          dmz = {
            enable = true;
            vlanId = 88;
            interface = "dmz0";
          };
        };
        suricata = {
          enable = true;
          inherit wanInterface;
          inherit lanInterface;
        };
        wireguard.server = {
          enable = true;
          inherit wgInterface lanInterface;
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
          interface = lanInterface;
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
          interface = lanInterface;
        };
        dockhand.agent.enable = true;
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          interface = lanInterface;
        };
        wazuh.agent = {
          enable = true;
          interface = lanInterface;
        };
      };
    };
  };
}
