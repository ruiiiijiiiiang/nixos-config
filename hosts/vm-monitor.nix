{ inputs, ... }:
let
  hostName = "vm-monitor";
  lanInterface = "lan0";
  backupPath = "/mnt/usb-hdd-1/${hostName}/backup";
in
{
  imports = [
    inputs.nixos-vm-provisioner.nixosModules.guest-base
  ];

  system.stateVersion = "25.11";
  networking.hostName = hostName;

  nixos-vm-provisioner.guest.enable = true;

  custom = {
    platforms.vm = {
      kernel.enable = true;
      disks = {
        enable = true;
        swap = {
          enable = true;
          size = 4096;
        };
      };
      networking = {
        enable = true;
        inherit lanInterface;
      };
    };

    roles.headless = {
      networking.enable = true;
      packages.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
      infra = {
        podman = {
          enable = true;
          autoUpdate.enable = true;
          autoBackup = {
            enable = true;
            path = backupPath;
          };
        };
        restic = {
          enable = true;
          repo = backupPath;
        };
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
        ntfy.enable = true;
        prometheus = {
          server.enable = true;
          exporters = {
            nginx.enable = true;
            node.enable = true;
            podman.enable = true;
            restic.enable = true;
          };
        };
        termix.enable = true;
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
