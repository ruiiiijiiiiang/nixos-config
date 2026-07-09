{
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts) username daily-tasks;
  inherit (helpers) dailyTaskToSystemd adjustTime;
  cfg = config.custom.services.infra.restic;

  sharedConfig = {
    initialize = true;
    passwordFile = config.age.secrets.restic-password.path;
    paths = [
      "/etc/ssh/ssh_host_*"
      "/home/${username}/.ssh/id_*"
      "/var/lib"
    ]
    ++ cfg.extraPaths;

    exclude = [
      "/var/lib/containers"
      "/var/lib/systemd"
      "/var/lib/machines"
      "**/.cache"
    ];

    extraBackupArgs = [ "--exclude-caches" ];
  };
in
{
  options.custom.services.infra.restic = with lib; {
    enable = mkEnableOption "Enable Restic config";
    repo = mkOption {
      type = types.str;
      description = "Base path to store the Restic repository.";
    };
    extraPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra paths to backup data from.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.repo;
        message = "custom.services.infra.restic.repo must be an absolute path.";
      }
      {
        assertion = lib.all (p: lib.hasPrefix "/" p) cfg.extraPaths;
        message = "custom.services.infra.restic.extraPaths must contain only absolute paths.";
      }
    ];

    age.secrets = {
      restic-password.file = ../../../../secrets/restic-password.age;
      rclone-conf.file = ../../../../secrets/rclone-conf.age;
    };

    services.restic.backups = {
      "data-local" = sharedConfig // {
        repository = "${cfg.repo}/restic-repo";
        timerConfig = {
          OnCalendar = dailyTaskToSystemd daily-tasks.${config.networking.hostName}.restic-backup;
        };
        pruneOpts = [
          "--keep-daily 4"
          "--keep-weekly 2"
          "--keep-monthly 1"
        ];
      };

      "data-proton" = sharedConfig // {
        repository = "rclone:proton-drive:restic-repo-${config.networking.hostName}";
        rcloneConfigFile = config.age.secrets.rclone-conf.path;
        timerConfig = {
          OnCalendar = dailyTaskToSystemd (
            adjustTime "+15m" daily-tasks.${config.networking.hostName}.restic-backup
          );
        };
        pruneOpts = [
          "--keep-last 3"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.repo} 0755 - - - -"
    ];
  };
}
