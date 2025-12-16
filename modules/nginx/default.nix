{ config, lib, ... }:
with lib;
let
  cfg = config.rui.nginx;
  consts = import ../../lib/consts.nix;
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      cloudflare-token = {
        file = ../../secrets/cloudflare-token.age;
        owner = "acme";
        group = "acme";
        mode = "440";
      };
    };

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
            limit_req_zone $binary_remote_addr zone=microbin_req_limit:10m rate=1r/s;
            limit_conn_zone $binary_remote_addr zone=microbin_conn_limit:10m;
          ''}

          ${optionalString config.rui.website.enable ''
            limit_req_zone $binary_remote_addr zone=website_req_limit:10m rate=1r/s;
            limit_conn_zone $binary_remote_addr zone=website_conn_limit:10m;
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
      extraGroups = [ "acme" ];
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "me@ruijiang.me";
      certs."${domains.home}" = {
        domain = domains.home;
        extraDomainNames = [ "*.${domains.home}" ];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        environmentFile = config.age.secrets.cloudflare-token.path;
        group = "nginx";
        reloadServices = [ "nginx" ];
      };
    };
  };
}
