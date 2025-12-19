{
  config,
  lib,
  ...
}:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.dyndns;
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      cloudflare-dns-token = {
        file = ../../../secrets/cloudflare-dns-token.age;
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
