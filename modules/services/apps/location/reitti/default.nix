{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../../../lib/consts.nix)
    addresses
    domain
    subdomains
    ports
    oci-uids
    endpoints
    ;
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.location.reitti;
  fqdn = "${subdomains.${config.networking.hostName}.reitti}.${domain}";
in
{
  options.custom.services.apps.location.reitti = with lib; {
    enable = mkEnableOption "Enable Reitti";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      reitti-env.file = ../../../../../secrets/reitti-env.age;
      # POSTGRES_USER
      # POSTGRES_DB
      # POSTGRES_PASSWORD
      # POSTGIS_USER
      # POSTGIS_DB
      # POSTGIS_PASSWORD
      # OIDC_CLIENT_ID
      # OIDC_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers = {
      reitti-postgis = {
        image = "postgis/postgis:17-3.5-alpine";
        ports = [ "${addresses.localhost}:${toString ports.reitti}:${toString ports.reitti}" ];
        environmentFiles = [ config.age.secrets.reitti-env.path ];
        volumes = [ "/var/lib/reitti/postgis:/var/lib/postgresql/data" ];
      };

      reitti-redis = {
        image = "docker.io/library/redis:latest";
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        extraOptions = [ "--tmpfs=/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      reitti-tile-cache = {
        image = "docker.io/dedicatedcode/reitti-tile-cache:next";
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        environment = {
          APP_UID = toString oci-uids.reitti;
          APP_GID = toString oci-uids.reitti;
        };
        volumes = [ "reitti-tile-cache-data:/var/cache/nginx" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      reitti-server = {
        image = "docker.io/dedicatedcode/reitti:next";
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        environment = {
          SERVER_PORT = toString ports.reitti;
          POSTGIS_HOST = addresses.localhost;
          REDIS_HOST = addresses.localhost;
          TILES_CACHE = "http://${addresses.localhost}";
          OIDC_ENABLED = "true";
          OIDC_ISSUER_URI = "https://${endpoints.oidc-issuer}";
          APP_UID = toString oci-uids.reitti;
          APP_GID = toString oci-uids.reitti;
        };
        environmentFiles = [ config.age.secrets.reitti-env.path ];
        volumes = [ "/var/lib/reitti/data:/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/reitti/postgis 0700 ${toString oci-uids.postgres-alpine} ${toString oci-uids.postgres-alpine} - -"
        "d /var/lib/reitti/data 0700 ${toString oci-uids.reitti} ${toString oci-uids.reitti} - -"
      ];

      services.podman-reitti-postgis = mkNotifyService { timeout = 600; };
    };

    users = mkOciUser "reitti";

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.reitti;
    };
  };
}
