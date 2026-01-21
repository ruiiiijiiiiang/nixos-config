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
    domains
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.media.immich;
  fqdn = "${subdomains.${config.networking.hostName}.immich}.${domains.home}";
  immich-version = "v2.4.1";
in
{
  options.custom.services.apps.media.immich = with lib; {
    enable = mkEnableOption "Immich photo and video storage";
  };

  config = lib.mkIf cfg.enable {
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
        autoStart = true;
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
        autoStart = true;
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
        autoStart = true;
        user = "${toString oci-uids.immich}:${toString oci-uids.immich}";
        dependsOn = [
          "immich-redis"
          "immich-postgres"
        ];
        networks = [ "container:immich-postgres" ];
        environment = {
          REDIS_HOSTNAME = addresses.localhost;
          DB_HOSTNAME = addresses.localhost;
          IMMICH_MACHINE_LEARNING_URL = "http://localhost:3003";
          TZ = timeZone;
        };
        environmentFiles = [ config.age.secrets.immich-env.path ];
        volumes = [
          "/var/storage/immich:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };

      immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:${immich-version}";
        autoStart = true;
        user = "${toString oci-uids.immich}:${toString oci-uids.immich}";
        dependsOn = [ "immich-postgres" ];
        networks = [ "container:immich-postgres" ];
        volumes = [
          "/var/lib/immich/model-cache:/cache"
        ];
      };
    };

    users = mkOciUser "immich";

    systemd.tmpfiles.rules = [
      "d /var/lib/immich/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
      "d /var/lib/immich/model-cache 0755 ${toString oci-uids.immich} ${toString oci-uids.immich} - -"
      "d /var/storage/immich 0755 ${toString oci-uids.immich} ${toString oci-uids.immich} - -"
    ];

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
