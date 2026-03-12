{ consts, ... }:
let
  inherit (consts) vlan-ids;
  lanInterface = "lan0";
  vlanId = vlan-ids.infra;
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-monitor";

  custom = {
    platforms.vm = {
      kernel.enable = true;

      libvirt = {
        enable = true;
        cpu = 4;
        memory = 4;
        inherit vlanId;
        autoStart = true;
      };

      disks = {
        enable = true;
        size = 100;
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
        nfs.server.enable = true;
        podman.enable = true;
      };

      networking.nginx.enable = true;

      observability = {
        beszel = {
          hub.enable = true;
          agent.enable = true;
        };
        dockhand.server.enable = true;
        gatus.enable = true;
        grafana.enable = true;
        loki = {
          server.enable = true;
          agent.enable = true;
        };
        myspeed.enable = true;
        prometheus = {
          server.enable = true;
          exporters = {
            nginx.enable = true;
            node.enable = true;
            podman.enable = true;
          };
        };
      };

      security = {
        fail2ban.enable = true;
        wazuh = {
          server.enable = true;
          agent.enable = true;
        };
      };
    };
  };
}
