{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts)
    timeZone
    addresses
    domains
    subdomains
    ports
    id-fqdn
    ;
  cfg = config.custom.selfhost.dawarich;
  fqdn = "${subdomains.${config.networking.hostName}.dawarich}.${domains.home}";
in
{
  options.custom.selfhost.dawarich = with lib; {
    enable = mkEnableOption "Dawarich GPS tracking service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      dawarich-env.file = ../../../secrets/dawarich-env.age;
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
      dawarich-db = {
        image = "postgis/postgis:16-3.4-alpine";
        ports = [ "${addresses.localhost}:${toString ports.dawarich}:${toString ports.dawarich}" ];
        environmentFiles = [ config.age.secrets.dawarich-env.path ];
        volumes = [ "dawarich-db-data:/var/lib/postgresql/data" ];
      };

      dawarich-redis = {
        image = "docker.io/library/redis:latest";
        dependsOn = [ "dawarich-db" ];
        networks = [ "container:dawarich-db" ];
        volumes = [ "dawarich-redis-data:/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      dawarich-app = {
        image = "docker.io/freikin/dawarich:latest";
        dependsOn = [
          "dawarich-db"
          "dawarich-redis"
        ];
        networks = [ "container:dawarich-db" ];
        environment = {
          APPLICATION_HOSTS = fqdn;
          TIME_ZONE = timeZone;
          ALLOW_REGISTRATION = "true";
          DATABASE_HOST = addresses.localhost;
          REDIS_URL = "redis://${addresses.localhost}:${toString ports.redis}/0";
          OIDC_ISSUER = "https://${id-fqdn}";
          OIDC_REDIRECT_URI = "https://${fqdn}/users/auth/openid_connect/callback";
          OIDC_PROVIDER_NAME = "PocketID";
        };
        environmentFiles = [ config.age.secrets.dawarich-env.path ];
        volumes = [
          "dawarich-storage:/var/app/storage"
          "dawarich-public:/var/app/public"
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
        dependsOn = [
          "dawarich-db"
          "dawarich-redis"
          "dawarich-app"
        ];
        networks = [ "container:dawarich-db" ];
        environment = {
          APPLICATION_HOSTS = fqdn;
          TIME_ZONE = timeZone;
          DATABASE_HOST = addresses.localhost;
          REDIS_URL = "redis://${addresses.localhost}:${toString ports.redis}/0";
        };
        environmentFiles = [ config.age.secrets.dawarich-env.path ];
        volumes = [
          "dawarich-storage:/var/app/storage"
          "dawarich-public:/var/app/public"
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

    services.nginx.virtualHosts."${fqdn}" = {
      useACMEHost = fqdn;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.dawarich}";
      };
      locations."/cable" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.dawarich}";
      };
    };
  };
}
