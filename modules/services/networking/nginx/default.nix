{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (lib)
    mkIf
    optionalString
    genAttrs
    ;
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

  config = mkIf cfg.enable {
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
          allow ${addresses.home.network};
          allow ${addresses.infra.network};
          allow ${addresses.dmz.network};
          allow ${addresses.vpn.network};
          allow ${addresses.podman.network};
          deny all;

          ${optionalString config.custom.services.observability.prometheus.exporters.nginx.enable ''
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

          ${optionalString config.custom.services.apps.tools.microbin.enable ''
            limit_req_zone $binary_remote_addr zone=microbin_req_limit:10m rate=1r/s;
            limit_conn_zone $binary_remote_addr zone=microbin_conn_limit:10m;
          ''}

          ${optionalString config.custom.services.apps.web.website.enable ''
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
