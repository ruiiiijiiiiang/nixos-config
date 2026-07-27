{
  secretsDir,
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (config.networking) hostName;
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
      "/var/lib/swapfile"
    ]
    ++ cfg.extraExcludes;

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
    extraExcludes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional paths contributed by enabled service modules.";
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
      {
        assertion = lib.all (p: lib.hasPrefix "/" p) cfg.extraExcludes;
        message = "custom.services.infra.restic.extraExcludes must contain only absolute paths.";
      }
    ];

    age.secrets = {
      restic-password.file = secretsDir + "/infra/restic/password.age";
      rclone-conf.file = secretsDir + "/infra/restic/rclone.conf.age";
    };

    services.restic.backups = {
      "data-local" = sharedConfig // {
        repository = "${cfg.repo}/restic-repo";
        timerConfig = {
          OnCalendar = dailyTaskToSystemd daily-tasks.${hostName}.restic-backup;
        };
        pruneOpts = [
          "--keep-daily 3"
          "--keep-weekly 1"
          "--keep-monthly 1"
        ];
      };

      "data-proton" = sharedConfig // {
        repository = "rclone:proton-drive:backup/restic-repo-${hostName}";
        rcloneConfigFile = config.age.secrets.rclone-conf.path;
        rcloneOptions = {
          transfers = "1";
          checkers = "1";
          tpslimit = "1";
          protondrive-thread-count = "1";
          protondrive-enable-caching = "false";
          timeout = "10m";
          contimeout = "2m";
          protondrive-replace-existing-draft = "true";
        };
        extraOptions = [ "rclone.connections=1" ];
        extraBackupArgs = sharedConfig.extraBackupArgs ++ [
          "--pack-size"
          "8"
        ];
        timerConfig = {
          OnCalendar = dailyTaskToSystemd (adjustTime "+15m" daily-tasks.${hostName}.restic-backup);
        };
        pruneOpts = [
          "--keep-last 3"
          "--pack-size 8"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.repo} 0755 - - - -"
    ];
  };
}
