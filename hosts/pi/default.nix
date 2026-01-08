{
  imports = [
    ../../modules
    ./hardware.nix
    ./packages.nix
  ];

  system.stateVersion = "25.05";
  networking.hostName = "pi";

  custom = {
    server = {
      network.enable = true;
      security.enable = true;
      services.enable = true;
    };

    selfhost = {
      dns.enable = true;
      homeassistant.enable = true;
      nginx.enable = true;

      beszel.agent.enable = true;
      dockhand.agent.enable = true;
      prometheus.exporters = {
        nginx.enable = true;
        node.enable = true;
        podman.enable = true;
      };
      scanopy.daemon.enable = true;
    };
  };
}
