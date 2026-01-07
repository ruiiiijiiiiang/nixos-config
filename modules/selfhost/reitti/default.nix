{
  config,
  lib,
  utilFns,
  ...
}:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.selfhost.reitti;
  fqdn = "${subdomains.${config.networking.hostName}.reitti}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      reitti-env.file = ../../../secrets/reitti-env.age;
    };

    virtualisation.oci-containers.containers = {
      reitti-postgis = {
        image = "postgis/postgis:17-3.5-alpine";
        ports = [ "${addresses.localhost}:${toString ports.reitti}:${toString ports.reitti}" ];
        environmentFiles = [ config.age.secrets.reitti-env.path ];
        volumes = [ "reitti-postgis-data:/var/lib/postgresql/data" ];
      };

      reitti-rabbitmq = {
        image = "rabbitmq:3-management-alpine";
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        environmentFiles = [ config.age.secrets.reitti-env.path ];
        volumes = [ "reitti-rabbitmq-data:/var/lib/rabbitmq" ];
      };

      reitti-redis = {
        image = "redis:7-alpine";
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        volumes = [ "reitti-redis-data:/data" ];
      };

      reitti-photon = {
        image = "rtuszik/photon-docker:1.2.1";
        dependsOn = [ "reitti-postgis" ];
        networks = [ "container:reitti-postgis" ];
        environment = {
          UPDATE_STRATEGY = "PARALLEL";
          REGION = "us";
        };
        volumes = [ "reitti-photon-data:/photon/data" ];
      };

      reitti-tile-cache = {
        image = "nginx:alpine";
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
                  proxy_set_header User-Agent "Reitti/1.0 (+https://github.com/dedicatedcode/reitti; contact: reitti@dedicatedcode.com)";
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
      };

      reitti-server = {
        image = "dedicatedcode/reitti:latest";
        dependsOn = [
          "reitti-postgis"
          "reitti-rabbitmq"
          "reitti-redis"
          "reitti-photon"
          "reitti-tile-cache"
        ];
        networks = [ "container:reitti-postgis" ];
        environment = {
          SERVER_PORT = "${toString ports.reitti}";
          PHOTON_BASE_URL = "http://${addresses.localhost}:2322";
          POSTGIS_HOST = addresses.localhost;
          RABBITMQ_HOST = addresses.localhost;
          REDIS_HOST = addresses.localhost;
          TILES_CACHE = "http://${addresses.localhost}";
          OIDC_ENABLED = "true";
          OIDC_ISSUER_URI = "https://id.${domains.home}";
        };
        environmentFiles = [ config.age.secrets.reitti-env.path ];
        volumes = [ "/var/lib/reitti/data:/data" ];
        extraOptions = [ "--pull=always" ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/reitti/data 0750 reitti reitti -"
    ];

    users.groups.reitti = { };
    users.users.reitti = {
      isSystemUser = true;
      group = "reitti";
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.reitti;
      proxyWebsockets = true;
    };
  };
}
