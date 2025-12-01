{ config, lib, ... }:
with lib;
let
  cfg = config.rui.microbin;
  consts = import ../../lib/consts.nix;
in with consts; {
  config = mkIf cfg.enable {
    services = {
      microbin = {
        enable = true;
        settings = {
          MICROBIN_BIND = addresses.localhost;
          MICROBIN_PORT = ports.microbin;
        };
      };

      nginx.virtualHosts."microbin.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.microbin}";
        };
        extraConfig = ''
          limit_req zone=microbin_limit burst=10 nodelay;
        '';
      };
    };
  };
}
