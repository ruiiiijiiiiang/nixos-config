{ consts, ... }:
let
  inherit (consts) vlan-ids;
  hostName = "vm-monitor";
  lanInterface = "lan0";
  vlanId = vlan-ids.infra;
  backupPath = "/mnt/usb-hdd-1/${hostName}/backup";
in
{
  system.stateVersion = "25.11";
  networking.hostName = hostName;

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
          backupLocalDatabases = true;
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
        myspeed.enable = true;
        prometheus = {
          server.enable = true;
          exporters = {
            nginx.enable = true;
            node.enable = true;
            podman.enable = true;
            restic.enable = true;
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
