let
  podmanInterface = "podman0";
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-monitor";

  custom = {
    roles.headless = {
      network = {
        enable = true;
        inherit podmanInterface;
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
      networking.nginx.enable = true;

      observability = {
        beszel = {
          hub.enable = true;
          agent.enable = true;
        };
        dockhand.server.enable = true;
        gatus.enable = true;
        myspeed.enable = true;
        prometheus = {
          server.enable = true;
          exporters = {
            nginx.enable = true;
            node.enable = true;
            podman.enable = true;
          };
        };
        wazuh = {
          server.enable = true;
          agent.enable = true;
        };
      };
    };
  };
}
