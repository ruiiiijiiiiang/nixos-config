{
  config,
  lib,
  consts,
  ...
}:
let
  inherit (consts) endpoints;
  cfg = config.custom.services.networking.dyndns;
in
{
  options.custom.services.networking.dyndns = with lib; {
    enable = mkEnableOption "Enable dynamic DNS";
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
      domains = [ endpoints.vpn ];
      proxied = false;
    };
  };
}
