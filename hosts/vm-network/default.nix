{ config, ... }:
let
  wanInterface = "ens18";
  lanInterface = "ens19";
  wireguardInterface = "wg0";
in
{
  imports = [
    ../../modules
  ];

  system.stateVersion = "25.11";
  networking.hostName = "vm-network";

  age.secrets = {
    wireguard-server-private-key.file = ../../secrets/wireguard/server-private-key.age;
  };

  custom = {
    server = {
      network.enable = true;
      security.enable = true;
      services.enable = true;
    };

    vm = {
      hardware.enable = true;
      disks = {
        enableMain = true;
        enableStorage = true;
      };
    };

    selfhost = {
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

      dns.enable = true;
      dyndns.enable = true;
      nginx.enable = true;

      beszel.agent.enable = true;
      dockhand.agent.enable = true;
      prometheus.exporters = {
        nginx.enable = true;
        node.enable = true;
      };
      scanopy.daemon.enable = true;
      wazuh.agent.enable = true;
    };
  };
}
