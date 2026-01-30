{ config, ... }:
let
  podmanInterface = "podman0";
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-monitor";

  age.secrets = {
    scanopy-daemon-vm-monitor-env.file = ../../secrets/scanopy/daemon-vm-monitor-env.age;
  };

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
        scanopy = {
          server.enable = true;
          daemon = {
            enable = true;
            envFile = config.age.secrets.scanopy-daemon-vm-monitor-env.path;
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
