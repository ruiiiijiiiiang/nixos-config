{
  config,
  consts,
  lib,
  utilFns,
  ...
}:
let
  inherit (consts)
    timeZone
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.custom.selfhost.immich;
  fqdn = "${subdomains.${config.networking.hostName}.immich}.${domains.home}";
  immich-version = "v2.4.1";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      immich-env.file = ../../../secrets/immich-env.age;
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
        image = "redis:latest";
        dependsOn = [ "immich-postgres" ];
        networks = [ "container:immich-postgres" ];
        cmd = [ "redis-server" ];
        volumes = [ "immich-redis-data:/data" ];
      };

      immich-server = {
        image = "ghcr.io/immich-app/immich-server:${immich-version}";
        dependsOn = [
          "immich-redis"
          "immich-postgres"
        ];
        networks = [ "container:immich-postgres" ];
        environment = {
          TZ = timeZone;
          REDIS_HOSTNAME = addresses.localhost;
          DB_HOSTNAME = addresses.localhost;
          IMMICH_MACHINE_LEARNING_URL = "http://localhost:3003";
        };
        environmentFiles = [ config.age.secrets.immich-env.path ];
        volumes = [
          "/var/storage/immich:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];
        user = "1001:1001";
      };

      immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:${immich-version}";
        dependsOn = [ "immich-postgres" ];
        networks = [ "container:immich-postgres" ];
        volumes = [
          "/var/lib/immich/model-cache:/cache"
        ];
        user = "1001:1001";
      };
    };

    users.groups.immich = {
      gid = 1001;
    };
    users.users.immich = {
      isSystemUser = true;
      group = "immich";
      uid = 1001;
      createHome = false;
    };

    systemd.tmpfiles.rules = [
      "d /var/storage/immich 0755 1001 1001 - -"
      "d /var/storage/immich/thumbs 0755 1001 1001 - -"
      "d /var/storage/immich/encoded-video 0755 1001 1001 - -"
      "d /var/storage/immich/profile 0755 1001 1001 - -"
      "d /var/lib/immich/model-cache 0755 1001 1001 - -"
      "d /var/lib/immich/postgres 0700 999 999 - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.immich;
        proxyWebsockets = true;
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
