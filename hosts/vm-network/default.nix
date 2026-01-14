{ config, ... }:
let
  wanInterface = "ens18";
  lanInterface = "ens19";
  wireguardInterface = "wg0";
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-network";

  age.secrets = {
    wireguard-server-private-key.file = ../../secrets/wireguard/server-private-key.age;
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
        };
        suricata = {
          enable = true;
          inherit wanInterface;
          inherit lanInterface;
        };
        wireguard.server = {
          enable = true;
          privateKeyFile = config.age.secrets.wireguard-server-private-key.path;
          interface = wireguardInterface;
        };
        dns = {
          enable = true;
          vrrp = {
            interface = lanInterface;
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
        beszel.agent.enable = true;
        dockhand.agent.enable = true;
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
        };
        wazuh.agent.enable = true;
      };
    };
  };
}
