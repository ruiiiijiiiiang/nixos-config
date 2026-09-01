{
  secretsDir,
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts) domain subdomains;
  inherit (helpers) getHostAddress;
  cfg = config.custom.services.networking.cloudflared;

  tunneledSubdomains = [
    subdomains.vm-public.website
    subdomains.vm-public.microbin
    subdomains.vm-public.krawl
  ];

  mkIngress = fqdn: {
    service = "https://${getHostAddress "vm-public"}:443";
    originRequest = {
      originServerName = fqdn;
      noTLSVerify = true;
    };
  };

  ingressRules = lib.genAttrs (map (
    subdomain: "${subdomain}.${domain}"
  ) tunneledSubdomains) mkIngress;
in
{
  options.custom.services.networking.cloudflared = with lib; {
    enable = mkEnableOption "Enable Cloudflare tunnel";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      cloudflared-tunnel-token.file = secretsDir + "/networking/cloudflare/tunnel-token.age";
    };

    # To add a tunnel, do `cloudflared tunnel route dns home {subdomain}.ruijiang.me` after `cloudflared tunnel login`
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
