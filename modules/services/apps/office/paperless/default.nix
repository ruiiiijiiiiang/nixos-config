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
  cfg = config.custom.services.apps.office.paperless;
  fqdn = "${subdomains.${config.networking.hostName}.paperless}.${domains.home}";
in
{
  options.custom.services.apps.office.paperless = with lib; {
    enable = mkEnableOption "Paperless-ngx document management";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      paperless-env.file = ../../../../../secrets/paperless-env.age;
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
      paperless-postgres = {
        image = "postgres:16";
        ports = [ "${addresses.localhost}:${toString ports.paperless}:8000" ];
        environmentFiles = [ config.age.secrets.paperless-env.path ];
        volumes = [ "/var/lib/paperless/postgres:/var/lib/postgresql/data" ];
      };

      paperless-redis = {
        image = "docker.io/library/redis:latest";
        cmd = [ "redis-server" ];
        dependsOn = [ "paperless-postgres" ];
        networks = [ "container:paperless-postgres" ];
        extraOptions = [ "--tmpfs=/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      paperless-app = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        dependsOn = [
          "paperless-postgres"
          "paperless-redis"
        ];
        networks = [ "container:paperless-postgres" ];

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

          USERMAP_UID = toString oci-uids.paperless;
          USERMAP_GID = toString oci-uids.paperless;
        };
        environmentFiles = [ config.age.secrets.paperless-env.path ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/storage/paperless 0700 ${toString oci-uids.paperless} ${toString oci-uids.paperless} - -"
      "d /var/storage/paperless/log 0700 ${toString oci-uids.paperless} ${toString oci-uids.paperless} - -"
      "d /var/storage/paperless/media 0700 ${toString oci-uids.paperless} ${toString oci-uids.paperless} - -"
      "d /var/storage/paperless/consume 0700 ${toString oci-uids.paperless} ${toString oci-uids.paperless} - -"
      "d /var/storage/paperless/data 0700 ${toString oci-uids.paperless} ${toString oci-uids.paperless} - -"
      "d /var/storage/paperless/data/data 0700 ${toString oci-uids.paperless} ${toString oci-uids.paperless} - -"
      "d /var/lib/paperless/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
    ];

    users = mkOciUser "paperless";

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.paperless;
      extraConfig = ''
        client_max_body_size 500M;
      '';
    };
  };
}
