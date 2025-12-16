{
  config,
  lib,
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
      cloudflare-dns-token = {
        file = ../../secrets/cloudflare-dns-token.age;
      };
    };

    systemd.services."acme-${domains.home}" = {
      environment = {
        LEGO_DISABLE_CNAME_SUPPORT = "true";
      };
    };

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
