{ config, lib, ... }:
with lib;
let
  cfg = config.selfhost.microbin;
  consts = import ../../../lib/consts.nix;
  fqdn = "${consts.subdomains.${config.networking.hostName}.microbin}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    services = {
      microbin = {
        enable = true;
        settings = {
          MICROBIN_BIND = addresses.localhost;
          MICROBIN_PORT = ports.microbin;
        };
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.microbin}";
        };
        extraConfig = ''
          allow all;
          limit_req zone=microbin_req_limit burst=10 nodelay;
          limit_conn microbin_conn_limit 20;

          keepalive_timeout 10;
          send_timeout 10;
          server_tokens off;

          client_max_body_size 10m;
          client_body_buffer_size 128k;

          add_header Referrer-Policy "no-referrer-when-downgrade" always;
          add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header X-Content-Type-Options "nosniff" always;
        '';
      };
    };
  };
}
