{ config, lib, ... }:
with lib;
let
  cfg = config.rui.seafile;
  consts = import ../../lib/consts.nix;
in
with consts;
{
  config = mkIf cfg.enable {
    # WIP

    services.nginx.virtualHosts."file.${domains.home}" = {
      useACMEHost = domains.home;
      forceSSL = true;
      clientMaxBodySize = "100G";
      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.seafile.web}";
        proxyWebsockets = true;
      };
      locations."/seafhttp" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.seafile.fileServer}";
        extraConfig = ''
          rewrite ^/seafhttp(.*)$ $1 break;
          proxy_connect_timeout  36000s;
          proxy_read_timeout  36000s;
          proxy_send_timeout  36000s;
          send_timeout  36000s;
        '';
      };
    };
  };
}
