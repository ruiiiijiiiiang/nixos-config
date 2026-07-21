{
  secretsDir,
  config,
  consts,
  helpers,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (consts) username daily-tasks;
  inherit (helpers) dailyTaskToSystemd;
  cfg = config.custom.services.infra.restic;
  localRepository = "${cfg.repo}/restic-repo";
  protonRepository = "proton-drive:backup/restic-repo-${hostName}-mirror";

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
      restic-password.file = secretsDir + "/infra/restic/password.age";
      rclone-conf.file = secretsDir + "/infra/restic/rclone.conf.age";
    };

    services.restic.backups = {
      "data-local" = sharedConfig // {
        repository = localRepository;
        timerConfig = {
          OnCalendar = dailyTaskToSystemd daily-tasks.${hostName}.restic-backup;
        };
        pruneOpts = [
          "--keep-daily 3"
          "--keep-weekly 1"
          "--keep-monthly 1"
        ];
      };
    };

    systemd = {
      services = {
        restic-backups-data-local = {
          unitConfig = {
            OnSuccess = [ "rclone-sync-restic-proton.service" ];
          };
        };

        rclone-sync-restic-proton = {
          description = "Mirror local Restic repository to Proton Drive";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          path = [ pkgs.rclone ];

          environment = {
            RCLONE_CONFIG = config.age.secrets.rclone-conf.path;
            RCLONE_TRANSFERS = "1";
            RCLONE_CHECKERS = "1";
            RCLONE_TPSLIMIT = "1";
            RCLONE_TPSLIMIT_BURST = "1";
            RCLONE_RETRIES = "5";
            RCLONE_LOW_LEVEL_RETRIES = "20";
            RCLONE_TIMEOUT = "10m";
            RCLONE_CONTIMEOUT = "2m";
            RCLONE_PROTONDRIVE_THREAD_COUNT = "1";
            RCLONE_PROTONDRIVE_REPLACE_EXISTING_DRAFT = "true";
          };

          serviceConfig = {
            Type = "oneshot";
            ExecCondition = pkgs.writeShellScript "rclone-sync-restic-proton-is-sunday" /* bash */ ''
              [[ "$(${lib.getExe' pkgs.coreutils "date"} +%u)" == 7 ]]
            '';
            Nice = 10;
            IOSchedulingClass = "idle";
          };

          script = /* bash */ ''
            exec rclone sync \
              ${lib.escapeShellArg localRepository} \
              ${lib.escapeShellArg protonRepository} \
              --delete-after \
              --stats 1m
          '';
        };
      };

      tmpfiles.rules = [
        "d ${cfg.repo} 0755 - - - -"
      ];
    };
  };
}
