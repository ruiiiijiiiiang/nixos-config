{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../../lib/consts.nix)
    addresses
    domains
    ports
    ;
  inherit (helpers) getEnabledSubdomains;
  cfg = config.custom.services.networking.nginx;
  subdomainList = getEnabledSubdomains { inherit config; };
in
{
  options.custom.services.networking.nginx = with lib; {
    enable = mkEnableOption "Nginx reverse proxy";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      cloudflare-token = {
        file = ../../../../secrets/cloudflare-token.age;
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
          allow 10.0.0.0/8;
          allow 172.16.0.0/12;
          allow 192.168.0.0/16;
          deny all;

          ${lib.optionalString config.custom.services.observability.prometheus.exporters.nginx.enable ''
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

          ${lib.optionalString config.custom.services.apps.tools.microbin.enable ''
            limit_req_zone $binary_remote_addr zone=microbin_req_limit:10m rate=1r/s;
            limit_conn_zone $binary_remote_addr zone=microbin_conn_limit:10m;
          ''}

          ${lib.optionalString config.custom.services.apps.web.website.enable ''
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
      certs = lib.genAttrs (map (name: "${name}.${domains.home}") subdomainList) (fqdn: {
        domain = fqdn;
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        environmentFile = config.age.secrets.cloudflare-token.path;
        group = "nginx";
        reloadServices = [ "nginx" ];
      });
    };

    systemd.services = lib.genAttrs (map (name: "acme-${name}.${domains.home}") subdomainList) (fqdn: {
      environment = {
        LEGO_DISABLE_CNAME_SUPPORT = "true";
      };
    });
  };
}
