{
  config,
  lib,
  consts,
  utilFns,
  ...
}:
let
  inherit (consts) domains subdomains ports;
  inherit (utilFns) mkVirtualHost;
  cfg = config.selfhost.pocketid;
  fqdn = "${subdomains.${config.networking.hostName}.pocketid}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      oauth2-env.file = ../../../secrets/oauth2-env.age;
    };

    services = {
      pocket-id = {
        enable = true;
        settings = {
          APP_URL = "https://${fqdn}";
          PORT = ports.pocketid;
          TRUST_PROXY = true;
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.pocketid;
        proxyWebsockets = true;
      };

      oauth2-proxy = {
        enable = false;
        keyFile = config.age.secrets.oauth2-env.path;
        httpAddress = "0.0.0.0:${toString ports.oauth2}";
        upstream = [ "static://202" ];
        provider = "oidc";
        oidcIssuerUrl = "https://${fqdn}";
        email.domains = [ "*" ];
        reverseProxy = true;
        scope = "openid email profile";
        cookie = {
          domain = ".${domains.home}";
          secure = true;
          httpOnly = true;
        };
        extraConfig = {
          "whitelist-domain" = ".ruijiang.me";
          "cookie-csrf-per-request" = true;
          "set-xauthrequest" = "true";
        };
      };
    };
  };
}
