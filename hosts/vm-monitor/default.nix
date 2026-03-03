{
  system.stateVersion = "25.11";
  networking.hostName = "vm-monitor";

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
        };
      };

      disks = {
        enable = true;
        size = "100GB";
      };
    };

    roles.headless = {
      networking.enable = true;
      podman.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
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
            # crowdsec.enable = true;
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
