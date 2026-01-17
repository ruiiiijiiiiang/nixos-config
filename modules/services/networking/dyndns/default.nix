{
  config,
  lib,
  consts,
  ...
}:
let
  inherit (consts) vpn-endpoint;
  cfg = config.custom.services.networking.dyndns;
in
{
  options.custom.services.networking.dyndns = with lib; {
    enable = mkEnableOption "dynamic DNS service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      cloudflare-dns-token = {
        file = ../../../../secrets/cloudflare-dns-token.age;
      };
    };

    services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = config.age.secrets.cloudflare-dns-token.path;
      domains = [ vpn-endpoint ];
      proxied = false;
    };

  };
}
