{
  imports = [
    ../../modules
  ];

  system.stateVersion = "25.11";
  networking.hostName = "vm-monitor";

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
      beszel = {
        hub.enable = true;
        agent.enable = true;
      };
      dockhand.server.enable = true;
      gatus.enable = true;
      nginx.enable = true;
      prometheus = {
        server.enable = true;
        exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
        };
      };
      scanopy = {
        server.enable = true;
        daemon.enable = true;
      };
      wazuh = {
        server.enable = true;
        agent.enable = true;
      };
    };
  };
}
