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
    oidc-issuer
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.tools.dawarich;
  fqdn = "${subdomains.${config.networking.hostName}.dawarich}.${domains.home}";
in
{
  options.custom.services.apps.tools.dawarich = with lib; {
    enable = mkEnableOption "Dawarich GPS tracking service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      dawarich-env.file = ../../../../../secrets/dawarich-env.age;
      # POSTGRES_DB
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # DATABASE_NAME
      # DATABASE_USERNAME
      # DATABASE_PASSWORD
      # OIDC_CLIENT_ID
      # OIDC_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers = {
      dawarich-postgis = {
        image = "postgis/postgis:16-3.4-alpine";
        autoStart = true;
        ports = [ "${addresses.localhost}:${toString ports.dawarich}:${toString ports.dawarich}" ];
        environmentFiles = [ config.age.secrets.dawarich-env.path ];
        volumes = [ "/var/lib/dawarich/postgis:/var/lib/postgresql/data" ];
      };

      dawarich-redis = {
        image = "docker.io/library/redis:latest";
        autoStart = true;
        dependsOn = [ "dawarich-postgis" ];
        networks = [ "container:dawarich-postgis" ];
        extraOptions = [ "--tmpfs=/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      dawarich-app = {
        image = "docker.io/freikin/dawarich:latest";
        autoStart = true;
        dependsOn = [
          "dawarich-postgis"
          "dawarich-redis"
        ];
        networks = [ "container:dawarich-postgis" ];
        environment = {
          APPLICATION_HOSTS = fqdn;
          TIME_ZONE = timeZone;
          ALLOW_REGISTRATION = "true";
          DATABASE_HOST = addresses.localhost;
          REDIS_URL = "redis://${addresses.localhost}:${toString ports.redis}/0";
          OIDC_ISSUER = "https://${oidc-issuer}";
          OIDC_REDIRECT_URI = "https://${fqdn}/users/auth/openid_connect/callback";
          OIDC_PROVIDER_NAME = "PocketID";
        };
        environmentFiles = [ config.age.secrets.dawarich-env.path ];
        volumes = [
          "/var/lib/dawarich/data/storage:/var/app/storage"
          "/var/lib/dawarich/data/public:/var/app/public"
        ];
        cmd = [
          "bin/rails"
          "server"
          "-p"
          "${toString ports.dawarich}"
          "-b"
          "::"
        ];
      };

      dawarich-sidekiq = {
        image = "docker.io/freikin/dawarich:latest";
        autoStart = true;
        dependsOn = [
          "dawarich-postgis"
          "dawarich-redis"
          "dawarich-app"
        ];
        networks = [ "container:dawarich-postgis" ];
        environment = {
          APPLICATION_HOSTS = fqdn;
          TIME_ZONE = timeZone;
          DATABASE_HOST = addresses.localhost;
          REDIS_URL = "redis://${addresses.localhost}:${toString ports.redis}/0";
        };
        environmentFiles = [ config.age.secrets.dawarich-env.path ];
        volumes = [
          "/var/lib/dawarich/data/storage:/var/app/storage"
          "/var/lib/dawarich/data/public:/var/app/public"
        ];
        cmd = [
          "bundle"
          "exec"
          "sidekiq"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "dawarich";

    systemd.tmpfiles.rules = [
      "d /var/lib/dawarich/postgis 0700 ${toString oci-uids.postgis} ${toString oci-uids.postgis} - -"
      "d /var/lib/dawarich/data/storage 0700 ${toString oci-uids.dawarich} ${toString oci-uids.dawarich} - -"
      "d /var/lib/dawarich/data/public 0700 ${toString oci-uids.dawarich} ${toString oci-uids.dawarich} - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.dawarich;
    };
  };
}
