{ config, inputs, ... }:
let
  lanInterface = "end0";
  wlanInterface = "wlan0";
  podmanInterface = "podman0";
  vlanId = 20;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  system.stateVersion = "25.05";
  networking.hostName = "pi";

  age.secrets = {
    scanopy-daemon-pi-env.file = ../../secrets/scanopy/daemon-pi-env.age;
  };

  custom = {
    platform.pi = {
      hardware.enable = true;
      network = {
        enable = true;
        inherit lanInterface wlanInterface vlanId;
      };
      packages.enable = true;
    };

    roles.headless = {
      network = {
        enable = true;
        inherit podmanInterface;
      };
      security.enable = true;
      services.enable = true;
    };

    services = {
      networking.dns = {
        enable = true;
        interface = "${lanInterface}.${toString vlanId}";
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
        scanopy = {
          daemon = {
            enable = true;
            envFile = config.age.secrets.scanopy-daemon-pi-env.path;
          };
        };
      };
    };
  };
}
