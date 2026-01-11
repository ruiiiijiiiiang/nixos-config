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
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.selfhost.paperless;
  fqdn = "${subdomains.${config.networking.hostName}.paperless}.${domains.home}";
in
{
  options.custom.selfhost.paperless = with lib; {
    enable = mkEnableOption "Paperless-ngx document management";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      paperless-env.file = ../../../secrets/paperless-env.age;
      # POSTGRES_DB
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # PAPERLESS_DBNAME
      # PAPERLESS_DBUSER
      # PAPERLESS_DBPASS
      # PAPERLESS_ADMIN_USER
      # PAPERLESS_ADMIN_PASSWORD
      # PAPERLESS_SOCIALACCOUNT_PROVIDERS
    };

    virtualisation.oci-containers.containers = {
      paperless-db = {
        image = "postgres:16";
        ports = [ "${addresses.localhost}:${toString ports.paperless}:8000" ];
        environmentFiles = [ config.age.secrets.paperless-env.path ];
        volumes = [ "/var/storage/paperless/data/postgres:/var/lib/postgresql/data" ];
      };

      paperless-redis = {
        image = "docker.io/library/redis:latest";
        cmd = [ "redis-server" ];
        dependsOn = [ "paperless-db" ];
        networks = [ "container:paperless-db" ];
        volumes = [ "paperless-redis-data:/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      paperless-app = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        dependsOn = [
          "paperless-db"
          "paperless-redis"
        ];
        networks = [ "container:paperless-db" ];

        volumes = [
          "/var/storage/paperless/log:/usr/src/paperless/log"
          "/var/storage/paperless/media:/usr/src/paperless/media"
          "/var/storage/paperless/consume:/usr/src/paperless/consume"
          "/var/storage/paperless/data/data:/usr/src/paperless/data"
        ];

        environment = {
          PAPERLESS_REDIS = "redis://${addresses.localhost}:${toString ports.redis}";
          PAPERLESS_DBHOST = addresses.localhost;
          PAPERLESS_URL = "https://${fqdn}";
          PAPERLESS_TIME_ZONE = timeZone;
          PAPERLESS_FILENAME_FORMAT = "{{ created_year }}/{{ correspondent }}/{{ title }}";

          PAPERLESS_OCR_CLEAN = "clean";
          PAPERLESS_OCR_DESKEW = "true";
          PAPERLESS_OCR_LANGUAGE = "eng";

          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS = "true";
          PAPERLESS_SOCIAL_AUTO_SIGNUP = "true";

          USERMAP_UID = toString config.users.users.paperless.uid;
          USERMAP_GID = toString config.users.groups.paperless.gid;
        };
        environmentFiles = [ config.age.secrets.paperless-env.path ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/storage/paperless               0750 paperless paperless -"
      "d /var/storage/paperless/log           0750 paperless paperless -"
      "d /var/storage/paperless/media         0750 paperless paperless -"
      "d /var/storage/paperless/consume       0750 paperless paperless -"
      "d /var/storage/paperless/data          0750 paperless paperless -"
      "d /var/storage/paperless/data/data     0750 paperless paperless -"
      "d /var/storage/paperless/data/postgres 0700 999 999 -"
    ];

    users.groups.paperless = { };
    users.users.paperless = {
      isSystemUser = true;
      group = "paperless";
      description = "Paperless-ngx OCI user";
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.paperless;
      extraConfig = ''
        client_max_body_size 500M;
      '';
    };
  };
}
