{ lib, config, ... }:
with lib;
let
  cfg = config.rui.cloudflared;
  consts = import ../../lib/consts.nix;
in with consts; {
  config = mkIf cfg.enable {
    age.secrets = {
      cloudflare-tunnel-token.file = ../../secrets/cloudflare-tunnel-token.age;
    };

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
            "microbin.${domains.home}" = {
              service = "https://${addresses.localhost}:443";
                originRequest = {
                originServerName = "microbin.${domains.home}";
              };
            };
            service = "http_status:404";
          };
        };
      };
    };
  };
}
