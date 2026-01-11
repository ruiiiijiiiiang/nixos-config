{ config, lib, ... }:
let
  inherit (import ../../../lib/consts.nix) domains;
  cfg = config.custom.selfhost.dyndns;
in
{
  options.custom.selfhost.dyndns = with lib; {
    enable = mkEnableOption "dynamic DNS service";
  };

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
        "vpn.${domains.home}"
      ];
      proxied = false;
    };

  };
}
