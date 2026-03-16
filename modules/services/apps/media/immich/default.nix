{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    timeZone
    addresses
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.media.immich;
  fqdn = "${subdomains.${config.networking.hostName}.immich}.${domain}";
  hasGpuPassthrough = config.custom.platforms.vm.kernel.hardwarePassthrough == "gpu";
  immich-version = "v2.5.6";
in
{
  options.custom.services.apps.media.immich = with lib; {
    enable = mkEnableOption "Enable Immich";
    storagePath = mkOption {
      type = types.str;
      description = "Path to store Immich data.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.storagePath;
        message = "custom.services.apps.media.immich.storagePath must be an absolute path string.";
      }
    ];

    age.secrets = {
      immich-env.file = ../../../../../secrets/immich-env.age;
      # POSTGRES_USER
      # POSTGRES_DB
      # POSTGRES_PASSWORD
      # DB_USERNAME
      # DB_DATABASE_NAME
      # DB_PASSWORD
    };

    virtualisation.oci-containers.containers = {
      immich-postgres = {
        image = "ghcr.io/immich-app/postgres:17-vectorchord0.5.3-pgvector0.8.1";
        ports = [ "${addresses.localhost}:${toString ports.immich}:${toString ports.immich}" ];
        environmentFiles = [ config.age.secrets.immich-env.path ];
        volumes = [
          "/var/lib/immich/postgres:/var/lib/postgresql/data"
        ];
        cmd = [
          "postgres"
          "-c"
          "shared_preload_libraries=vchord"
          "-c"
          "search_path=\"$user\",public,vectors"
          "-c"
          "logging_collector=on"
          "-c"
          "max_wal_size=2GB"
          "-c"
          "shared_buffers=512MB"
          "-c"
          "wal_compression=on"
        ];
      };

      immich-redis = {
        image = "docker.io/library/redis:latest";
        dependsOn = [ "immich-postgres" ];
        networks = [ "container:immich-postgres" ];
        cmd = [ "redis-server" ];
        extraOptions = [ "--tmpfs=/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      immich-server = {
        image = "ghcr.io/immich-app/immich-server:${immich-version}";
        user = "${toString oci-uids.immich}:${toString oci-uids.immich}";
        dependsOn = [ "immich-postgres" ];
        networks = [ "container:immich-postgres" ];
        environment = {
          REDIS_HOSTNAME = addresses.localhost;
          DB_HOSTNAME = addresses.localhost;
          IMMICH_MACHINE_LEARNING_URL = "http://localhost:3003";
          TZ = timeZone;
        };
        environmentFiles = [ config.age.secrets.immich-env.path ];
        volumes = [
          "${cfg.storagePath}/immich:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };

      immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:${immich-version}${lib.optionalString hasGpuPassthrough "-rocm"}";
        user = "${toString oci-uids.immich}:${toString oci-uids.immich}";
        dependsOn = [ "immich-postgres" ];
        networks = [ "container:immich-postgres" ];
        environment = {
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
          HOME = "/cache";
        };
        volumes = [
          "/var/lib/immich/model-cache:/cache"
        ];
        devices = [
          "/dev/dri:/dev/dri"
          "/dev/kfd:/dev/kfd"
        ];
      };
    };

    users = lib.mkMerge [
      (mkOciUser "immich")
      {
        users.immich.extraGroups = [
          "video"
          "render"
        ];
      }
    ];

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/immich/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
        "d /var/lib/immich/model-cache 0755 ${toString oci-uids.immich} ${toString oci-uids.immich} - -"
        "d ${cfg.storagePath}/immich 0755 ${toString oci-uids.immich} ${toString oci-uids.immich} - -"
      ];

      services.podman-immich-postgres = mkNotifyService { timeout = 900; };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.immich;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout 600s;
        '';
      };
    };
  };
}
