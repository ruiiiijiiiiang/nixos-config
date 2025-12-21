{ lib, config, ... }:
with lib;
let
  cfg = config.selfhost.immich;
  consts = import ../../../lib/consts.nix;
  fqdn = "${consts.subdomains.${config.networking.hostName}.immich}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    services = {
      immich = {
        enable = true;
        host = addresses.localhost;
        port = ports.immich;
        mediaLocation = "/var/storage/immich";
        machine-learning.enable = true;
        redis = {
          enable = true;
        };
      };

      postgresql = {
        enable = true;
        settings = {
          shared_buffers = "512MB";
          work_mem = "16MB";
        };
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.immich}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout 600s;
          '';
        };
      };
    };
  };
}
