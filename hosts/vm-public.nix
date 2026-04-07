{ consts, helpers, ... }:
let
  inherit (consts) vlan-ids;
  inherit (helpers) getHostAddress;
  hostName = "vm-public";
  lanInterface = "lan0";
  vlanId = vlan-ids.dmz;
in
{
  system.stateVersion = "25.11";
  networking.hostName = hostName;

  custom = {
    platforms.vm = {
      kernel.enable = true;

      libvirt = {
        enable = true;
        cpu = 4;
        memory = 2;
        inherit vlanId;
        autoStart = true;
      };

      disks = {
        enable = true;
        size = 20;
      };

      networking = {
        enable = true;
        inherit lanInterface;
      };
    };

    roles.headless = {
      networking.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
      infra = {
        podman = {
          enable = true;
          autoUpdate.enable = true;
        };
      };

      networking.nginx.enable = true;

      observability = {
        beszel.agent.enable = true;
        dockhand.agent.enable = true;
        loki.agent = {
          enable = true;
          serverAddress = getHostAddress "vm-monitor";
        };
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
        };
      };

      security = {
        fail2ban.enable = true;
        wazuh.agent = {
          enable = true;
          serverAddress = getHostAddress "vm-monitor";
        };
      };
    };
  };
}
