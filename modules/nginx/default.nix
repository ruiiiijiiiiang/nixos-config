{ config, lib, ... }:
with lib;
let
  cfg = config.rui.nginx;
  consts = import ../../lib/consts.nix;
in
with consts;
{
  config = mkIf cfg.enable {
    services = {
      nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        appendHttpConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          allow ${addresses.home.network};
          allow ${addresses.vpn.network};
          deny all;

          ${optionalString config.rui.microbin.enable ''
            limit_req_zone $binary_remote_addr zone=microbin_limit:10m rate=1r/s;
          ''}
        '';

        virtualHosts."_" = {
          default = true;
          rejectSSL = true;
          locations."/".return = "444";
        };
      };
    };

    users.users.nginx = {
      isSystemUser = true;
      group = "nginx";
    };
  };
}
