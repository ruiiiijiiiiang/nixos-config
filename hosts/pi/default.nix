{ config, inputs, ... }:
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
      network = {
        enable = true;
        inherit interface;
        vlan = {
          enable = true;
          id = 20;
        };
      };
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
        interface =
          let
            cfg = config.custom.platform.pi.network;
          in
          if cfg.vlan.enable then "${interface}.${toString cfg.vlan.id}" else interface;
        vrrp = {
          enable = true;
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
      };
    };
  };
}
