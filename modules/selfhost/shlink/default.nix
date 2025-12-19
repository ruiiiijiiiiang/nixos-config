{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.homepage;
  fqdn = "${consts.subdomains.${config.networking.hostName}.shlink}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      shlink-env.file = ../../../secrets/shlink-env.age;
    };

    virtualisation.oci-containers.containers = {
      shlink = {
        image = "shlinkio/shlink:stable";
        ports = [ "${toString ports.shlink.server}:8080" ];
        environment = {
          DEFAULT_DOMAIN = fqdn;
          IS_HTTPS_ENABLED = "true";
          DB_DRIVER = "sqlite";
          BASE_PATH = "/link";
        };
        volumes = [
          "/var/storage/shlink/data:/etc/shlink/data"
        ];
      };

      shlink-web = {
        image = "shlinkio/shlink-web-client:stable";
        ports = [ "${toString ports.shlink.web}:8080" ];
        environment = {
          SHLINK_SERVER_URL = "https://${fqdn}/link";
        };
        environmentFiles = [ config.age.secrets.shlink-env.path ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/shlink/data 0775 1001 0 -"
    ];

    services.nginx.virtualHosts."${fqdn}" = {
      useACMEHost = fqdn;
      forceSSL = true;
      locations."/link/" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.shlink.server}";
        extraConfig = ''
          allow all;
          limit_req zone=shlink_req_limit burst=10 nodelay;
          limit_conn shlink_conn_limit 20;

          keepalive_timeout 10;
          send_timeout 10;
          server_tokens off;

          client_max_body_size 16k;
          client_body_buffer_size 128k;

          add_header Referrer-Policy "no-referrer-when-downgrade" always;
          add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header X-Content-Type-Options "nosniff" always;
        '';
      };

      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.shlink.web}";
        proxyWebsockets = true;
      };
    };
  };
}
