{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.dawarich;
  fqdn = "${consts.subdomains.${config.networking.hostName}.dawarich}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      dawarich-env.file = ../../../secrets/dawarich-env.age;
    };

    virtualisation.oci-containers.containers = {
      dawarich-db = {
        image = "postgis/postgis:16-3.4-alpine";
        ports = [ "${addresses.localhost}:${toString ports.dawarich}:${toString ports.dawarich}" ];
        environmentFiles = [ config.age.secrets.dawarich-env.path ];
        volumes = [ "dawarich-db-data:/var/lib/postgresql/data" ];
      };

      dawarich-redis = {
        image = "redis:latest";
        dependsOn = [ "dawarich-db" ];
        extraOptions = [ "--network=container:dawarich-db" ];
        volumes = [ "dawarich-redis-data:/data" ];
      };

      dawarich-app = {
        image = "freikin/dawarich:latest";
        dependsOn = [
          "dawarich-db"
          "dawarich-redis"
        ];
        extraOptions = [ "--network=container:dawarich-db" ];
        environment = {
          APPLICATION_HOSTS = fqdn;
          TIME_ZONE = timeZone;
          ALLOW_REGISTRATION = "true";
          DATABASE_HOST = addresses.localhost;
          REDIS_URL = "redis://${addresses.localhost}:${toString ports.redis}/0";
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
        image = "freikin/dawarich:latest";
        dependsOn = [
          "dawarich-db"
          "dawarich-redis"
          "dawarich-app"
        ];
        extraOptions = [ "--network=container:dawarich-db" ];
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
        proxyWebsockets = true;
      };
    };
  };
}
