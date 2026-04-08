{
  config,
  lib,
  consts,
  helpers,
  ...
}:
let
  inherit (consts) domain;
  inherit (helpers) getHostAddress;
  cfg = config.custom.services.networking.cloudflared;

  tunneledSubdomains = [
    "public"
    "bin"
    "krawl"
  ];

  mkIngress = subdomain: {
    service = "https://${getHostAddress "vm-public"}:443";
    originRequest = {
      originServerName = "${subdomain}.${domain}";
      noTLSVerify = true;
    };
  };

  ingressRules = lib.genAttrs tunneledSubdomains mkIngress;
in
{
  options.custom.services.networking.cloudflared = with lib; {
    enable = mkEnableOption "Enable Cloudflare tunnel";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      cloudflared-tunnel-token.file = ../../../../secrets/cloudflared-tunnel-token.age;
    };

    services.cloudflared = {
      enable = true;
      tunnels = {
        "home" = {
          default = "http_status:404";
          credentialsFile = config.age.secrets.cloudflared-tunnel-token.path;
          ingress = ingressRules // {
            service = "http_status:404";
          };
        };
      };
    };
  };
}
