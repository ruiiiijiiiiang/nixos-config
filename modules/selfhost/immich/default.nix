{
  lib,
  config,
  consts,
  utilFns,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.selfhost.immich;
  fqdn = "${subdomains.${config.networking.hostName}.immich}.${domains.home}";
in
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

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.immich;
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
}
