{
  config,
  lib,
  inputs,
  ...
}:
with lib;
let
  consts = import ../../lib/consts.nix;
  cfg = config.rui.acme;
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
      cloudflare-dns-token = {
        file = ../../secrets/cloudflare-dns-token.age;
      };
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

    systemd.services."acme-${domains.home}" = {
      environment = {
        LEGO_DISABLE_CNAME_SUPPORT = "true";
      };
    };

    users.users.nginx.extraGroups = [ "acme" ];

    services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = config.age.secrets.cloudflare-dns-token.path;
      domains = [
        domains.home
        "*.${domains.home}"
      ];
      proxied = true;
    };
  };
}
