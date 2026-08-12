{
  config,
  consts,
  helpers,
  lib,
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

  # Original list: https://github.com/RealOrangeOne/docker-db-auto-backup/blob/master/db-auto-backup.py
  databaseProviders = [
    {
      images = [
        "postgres"
        "tensorchord/pgvecto-rs"
        "nextcloud/aio-postgresql"
        "timescale/timescaledb"
        "pgvector/pgvector"
        "pgautoupgrade/pgautoupgrade"
        "immich-app/postgres"
        "postgis/postgis"
        "kartoza/postgis"
      ];
      dataPath = "/var/lib/postgresql/data";
    }
    {
      images = [
        "mysql"
        "mariadb"
        "linuxserver/mariadb"
      ];
      dataPath = "/var/lib/mysql";
    }
    {
      images = [ "redis" ];
      dataPath = "/data";
    }
  ];

  normalizeImage =
    image:
    let
      withoutDigest = lib.head (lib.splitString "@" image);
      components = lib.splitString "/" withoutDigest;
      lastComponent = lib.last components;
      withoutTag = (lib.init components) ++ [ (lib.head (lib.splitString ":" lastComponent)) ];
      withoutRegistry =
        if
          lib.length withoutTag > 1
          && (
            lib.hasInfix "." (lib.head withoutTag)
            || lib.hasInfix ":" (lib.head withoutTag)
            || lib.head withoutTag == "localhost"
          )
        then
          lib.tail withoutTag
        else
          withoutTag;
      normalized =
        if lib.head withoutRegistry == "library" then lib.tail withoutRegistry else withoutRegistry;
    in
    lib.concatStringsSep "/" normalized;

  getDatabaseProvider =
    image:
    lib.findFirst (provider: lib.elem (normalizeImage image) provider.images) null databaseProviders;

  getDatabasePaths =
    container:
    let
      provider = getDatabaseProvider container.image;
    in
    lib.optionals (provider != null) (
      lib.concatMap (
        volume:
        let
          parts = lib.splitString ":" volume;
          source = lib.head parts;
        in
        lib.optionals (
          lib.length parts >= 2 && lib.hasPrefix "/" source && lib.elemAt parts 1 == provider.dataPath
        ) [ source ]
      ) container.volumes
    );

  databasePaths = lib.unique (
    lib.concatMap getDatabasePaths (lib.attrValues config.virtualisation.oci-containers.containers)
  );
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
      databasePaths = mkOption {
        type = types.listOf types.str;
        default = lib.optionals cfg.autoBackup.enable databasePaths;
        readOnly = true;
        description = "Host database paths covered by automatic logical backups.";
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
      custom.services.infra.restic = {
        extraExcludes = lib.optionals cfg.autoBackup.enable databasePaths;
      };

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
            dns_enabled = false;
            ipv6_enabled = true;
            subnets = [
              {
                subnet = addresses.podman.network;
                gateway = addresses.podman.gateway;
              }
              {
                subnet = addresses.podman.network-v6;
                gateway = addresses.podman.gateway-v6;
              }
            ];
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
