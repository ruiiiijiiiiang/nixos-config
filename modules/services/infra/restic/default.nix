{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.infra.restic;
in
{
  options.custom.services.infra.restic = with lib; {
    enable = mkEnableOption "Enable Restic config";
    repo = mkOption {
      type = types.str;
      description = "Base path to store the Restic repository.";
    };
    paths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Paths to backup data from.";
    };
    backupLocalDatabases = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically find and backup all .db files in /var/lib.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.repo;
        message = "custom.services.infra.restic.repo must be an absolute path.";
      }
      {
        assertion = lib.all (p: lib.hasPrefix "/" p) cfg.paths;
        message = "custom.services.infra.restic.paths must contain only absolute paths.";
      }
    ];

    age.secrets = {
      restic-password.file = ../../../../secrets/restic-password.age;
    };

    services.restic.backups."data-local" = {
      initialize = true;
      repository = "${cfg.repo}/restic-repo";
      passwordFile = config.age.secrets.restic-password.path;
      inherit (cfg) paths;

      dynamicFilesFrom = lib.mkIf cfg.backupLocalDatabases ''
        ${pkgs.findutils}/bin/find /var/lib -type f -name "*.db"
      '';

      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
      };

      pruneOpts = [
        "--keep-daily 3"
        "--keep-weekly 1"
        "--keep-monthly 1"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.repo} 0755 0 0 - -"
    ];
  };
}
