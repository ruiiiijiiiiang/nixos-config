{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    attrValues
    optionalString
    genAttrs
    ;
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.custom.selfhost.nginx;
  subdomainSet = subdomains.${config.networking.hostName} or null;
  subdomainList = if subdomainSet != null then attrValues subdomainSet else [ ];
in
{
  config = mkIf cfg.enable {
    age.secrets = {
      cloudflare-token = {
        file = ../../../secrets/cloudflare-token.age;
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
          allow ${addresses.localhost};
          allow ${addresses.localhost-v6};
          allow ${addresses.home.network};
          allow ${addresses.vpn.network};
          deny all;

          ${optionalString config.custom.selfhost.prometheus.exporters.nginx.enable ''
            server {
              listen ${addresses.localhost}:${toString ports.nginx.stub};
              server_name localhost;
              location /stub_status {
                stub_status on;
                access_log off;
                allow ${addresses.localhost};
                deny all;
              }
            }
          ''}

          ${optionalString config.custom.selfhost.microbin.enable ''
            limit_req_zone $binary_remote_addr zone=microbin_req_limit:10m rate=1r/s;
            limit_conn_zone $binary_remote_addr zone=microbin_conn_limit:10m;
          ''}

          ${optionalString config.custom.selfhost.website.enable ''
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
      certs = genAttrs (map (name: "${name}.${domains.home}") subdomainList) (fqdn: {
        domain = fqdn;
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        environmentFile = config.age.secrets.cloudflare-token.path;
        group = "nginx";
        reloadServices = [ "nginx" ];
      });
    };

    systemd.services = genAttrs (map (name: "acme-${name}.${domains.home}") subdomainList) (fqdn: {
      environment = {
        LEGO_DISABLE_CNAME_SUPPORT = "true";
      };
    });
  };
}
