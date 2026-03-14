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
  inherit (helpers) dailyTaskToCron;
  cfg = config.custom.services.infra.podman;
in
{
  options.custom.services.infra.podman = with lib; {
    enable = mkEnableOption "Enable Podman config";
    backup = {
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
          assertion = (!cfg.backup.enable) || cfg.enable;
          message = "custom.services.infra.podman.backup.enable requires custom.services.infra.podman.enable.";
        }
        {
          assertion = (!cfg.backup.enable) || (cfg.backup.path != null && lib.hasPrefix "/" cfg.backup.path);
          message = "custom.services.infra.podman.backup.path must be an absolute path string when backup is enabled.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      virtualisation = {
        containers.containersConf.settings = {
          containers = {
            dns_servers = [
              addresses.infra.vip.dns
            ];
          };
        };
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
            dns_enable = true;
          };
        };
        oci-containers = {
          backend = "podman";

          containers.db-auto-backup = lib.mkIf cfg.backup.enable {
            image = "ghcr.io/realorangeone/db-auto-backup:latest";
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock:ro"
              "${cfg.backup.path}:/var/backups"
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
        timers.podman-auto-update = {
          wantedBy = [ "timers.target" ];
          enable = true;
        };

        tmpfiles.rules = lib.mkIf cfg.backup.enable [
          "d ${cfg.backup.path} 0755 - - - -"
        ];
      };
    })
  ];
}
