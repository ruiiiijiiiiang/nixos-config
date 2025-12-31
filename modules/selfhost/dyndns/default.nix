{ config, lib, ... }:
let
  inherit (import ../../../lib/consts.nix) domains;
  cfg = config.selfhost.dyndns;
in
{
  config = lib.mkIf cfg.enable {
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
