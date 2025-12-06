{ lib, config, ... }:
with lib;
let
  cfg = config.rui.cloudflared;
  consts = import ../../lib/consts.nix;
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      cloudflare-tunnel-token.file = ../../secrets/cloudflare-tunnel-token.age;
    };

    # To add a tunnel, do `cloudflared tunnel route dns home {subdomain}.ruijiang.me`
    services.cloudflared = {
      enable = true;
      tunnels = {
        "home" = {
          default = "http_status:404";
          credentialsFile = config.age.secrets.cloudflare-tunnel-token.path;
          ingress = {
            "public.${domains.home}" = {
              service = "https://${addresses.localhost}:443";
              originRequest = {
                originServerName = "public.${domains.home}";
              };
            };
            "bin.${domains.home}" = {
              service = "https://${addresses.localhost}:443";
              originRequest = {
                originServerName = "bin.${domains.home}";
              };
            };
            service = "http_status:404";
          };
        };
      };
    };
  };
}
