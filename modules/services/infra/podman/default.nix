{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    username
    addresses
    oci-uids
    daily-tasks
    ;
  inherit (helpers) dailyTaskToSystemd dailyTaskToCron;
  cfg = config.custom.services.infra.podman;
in
{
  options.custom.services.infra.podman = with lib; {
    enable = mkEnableOption "Enable Podman config";
    autoUpdate.enable = mkEnableOption "Enable auto Podman update";
    autoBackup = {
      enable = mkEnableOption "Enable auto backup for containerized databases";
      path = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Absolute path to store database backups.";
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = config.virtualisation.oci-containers.containers == { } || cfg.enable;
          message = "OCI containers are defined but custom.services.infra.podman.enable is false.";
        }
        {
          assertion =
            (!cfg.autoBackup.enable) || (cfg.autoBackup.path != null && lib.hasPrefix "/" cfg.autoBackup.path);
          message = "custom.services.infra.podman.autoBackup.path must be an absolute path string when backup is enabled.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      virtualisation = {
        podman = {
          enable = true;
          dockerCompat = true;
          dockerSocket.enable = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
            flags = [ "--all" ];
          };
          defaultNetwork.settings = {
            dns_enabled = true;
          };
        };

        containers.containersConf.settings = {
          containers = {
            dns_servers = [
              addresses.infra.vip.dns
            ];
          };
        };

        oci-containers = {
          backend = "podman";

          containers.db-auto-backup = lib.mkIf cfg.autoBackup.enable {
            image = "ghcr.io/realorangeone/db-auto-backup:latest";
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock:ro"
              "${cfg.autoBackup.path}:/var/backups"
            ];
            environment = {
              SCHEDULE = dailyTaskToCron daily-tasks.${config.networking.hostName}.container-db-backup;
              COMPRESSION = "gzip";
            };
            labels = {
              "io.containers.autoupdate" = "registry";
            };
          };
        };
      };

      users = {
        users.${username}.extraGroups = [
          "podman"
        ];
        groups.podman.gid = oci-uids.podman;
      };

      systemd = {
        timers.podman-auto-update = lib.mkIf cfg.autoUpdate.enable {
          wantedBy = [ "timers.target" ];
          enable = true;
          timerConfig = {
            OnCalendar = [
              ""
              (dailyTaskToSystemd daily-tasks.${config.networking.hostName}.podman-update)
            ];
            RandomizedDelaySec = 0;
          };
        };

        tmpfiles.rules = lib.mkIf cfg.autoBackup.enable [
          "d ${cfg.autoBackup.path} 0755 - - - -"
        ];
      };
    })
  ];
}
