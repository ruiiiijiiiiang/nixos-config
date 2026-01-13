{ inputs, ... }:
let
  interface = "end0";
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  system.stateVersion = "25.05";
  networking.hostName = "pi";

  custom = {
    platform.pi = {
      hardware.enable = true;
      packages.enable = true;
    };

    roles.headless = {
      network.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
      networking.dns = {
        enable = true;
        vrrp = {
          inherit interface;
          state = "BACKUP";
          priority = 90;
        };
      };
      apps.tools.homeassistant.enable = true;
      networking.nginx.enable = true;

      observability = {
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
  };
}
