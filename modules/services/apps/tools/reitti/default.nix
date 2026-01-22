{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.tools.reitti;
  fqdn = "${subdomains.${config.networking.hostName}.reitti}.${domains.home}";
in
{
  options.custom.services.apps.tools.reitti = with lib; {
    enable = mkEnableOption "Reitti route planning service";
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
      # RABBITMQ_DEFAULT_USER
      # RABBITMQ_DEFAULT_PASS
      # OIDC_CLIENT_ID
      # OIDC_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers = {
      reitti-postgis = {
        image = "postgis/postgis:17-3.5-alpine";
        autoStart = true;
        ports = [ "${addresses.localhost}:${toString ports.reitti}:${toString ports.reitti}" ];
        environmentFiles = [ config.age.secrets.reitti-env.path ];
        volumes = [ "/var/lib/reitti/postgis:/var/lib/postgresql/data" ];
      };

      reitti-rabbitmq = {
        image = "docker.io/library/rabbitmq:latest";
        autoStart = true;
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        environmentFiles = [ config.age.secrets.reitti-env.path ];
        volumes = [ "reitti-rabbitmq-data:/var/lib/rabbitmq" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      reitti-redis = {
        image = "docker.io/library/redis:latest";
        autoStart = true;
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        extraOptions = [ "--tmpfs=/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      reitti-photon = {
        image = "ghcr.io/rtuszik/photon-docker:latest";
        autoStart = true;
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        environment = {
          UPDATE_STRATEGY = "PARALLEL";
          REGION = "us";
        };
        volumes = [ "reitti-photon-data:/photon/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      reitti-tile-cache = {
        image = "docker.io/library/nginx:alpine";
        autoStart = true;
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        cmd = [
          "sh"
          "-c"
          ''
            mkdir -p /var/cache/nginx/tiles
            cat > /etc/nginx/nginx.conf << 'EOF'
            events {
              worker_connections 1024;
            }
            http {
              proxy_cache_path /var/cache/nginx/tiles levels=1:2 keys_zone=tiles:10m max_size=1g inactive=30d use_temp_path=off;
              server {
                listen 80;
                location / {
                  proxy_pass https://tile.openstreetmap.org/;
                  proxy_set_header Host tile.openstreetmap.org;
                  proxy_set_header User-Agent "Reitti/1.0";
                  proxy_cache tiles;
                  proxy_cache_valid 200 30d;
                  proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
                }
              }
            }
            EOF
            nginx -g 'daemon off;'
          ''
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      reitti-server = {
        image = "docker.io/dedicatedcode/reitti:latest";
        autoStart = true;
        dependsOn = [
          "reitti-postgis"
          "reitti-rabbitmq"
          "reitti-redis"
          "reitti-photon"
          "reitti-tile-cache"
        ];
        networks = [ "container:reitti-postgis" ];
        environment = {
          SERVER_PORT = toString ports.reitti;
          PHOTON_BASE_URL = "http://${addresses.localhost}:2322";
          POSTGIS_HOST = addresses.localhost;
          RABBITMQ_HOST = addresses.localhost;
          REDIS_HOST = addresses.localhost;
          TILES_CACHE = "http://${addresses.localhost}";
          OIDC_ENABLED = "true";
          OIDC_ISSUER_URI = "https://id.${domains.home}";
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

    systemd.tmpfiles.rules = [
      "d /var/lib/reitti/postgis 0700 ${toString oci-uids.postgis} ${toString oci-uids.postgis} - -"
      "d /var/lib/reitti/data 0700 ${toString oci-uids.reitti} ${toString oci-uids.reitti} - -"
    ];

    users = mkOciUser "reitti";

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.reitti;
    };
  };
}
