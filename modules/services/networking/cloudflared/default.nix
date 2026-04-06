{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../../lib/consts.nix) domain;
  inherit (helpers) getHostAddress;
  cfg = config.custom.services.networking.cloudflared;
in
{
  options.custom.services.networking.cloudflared = with lib; {
    enable = mkEnableOption "Enable Cloudflare tunnel";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      cloudflare-tunnel-token.file = ../../../../secrets/cloudflare-tunnel-token.age;
    };

    services.cloudflared = {
      enable = true;
      tunnels = {
        "home" = {
          default = "http_status:404";
          credentialsFile = config.age.secrets.cloudflare-tunnel-token.path;
          ingress = {
            # To add a tunnel, do `cloudflared tunnel route dns home {subdomain}.ruijiang.me`
            "public.${domain}" = {
              service = "https://${getHostAddress "vm-app"}:443";
              originRequest = {
                originServerName = "public.${domain}";
              };
            };
            "bin.${domain}" = {
              service = "https://${getHostAddress "vm-app"}:443";
              originRequest = {
                originServerName = "bin.${domain}";
              };
            };
            service = "http_status:404";
          };
        };
      };
    };
  };
}
