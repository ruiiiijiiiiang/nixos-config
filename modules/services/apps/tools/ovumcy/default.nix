{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    timeZone
    addresses
    domain
    subdomains
    ports
    oci-uids
    endpoints
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.tools.ovumcy;
  fqdn = "${subdomains.${config.networking.hostName}.ovumcy}.${domain}";
in
{
  options.custom.services.apps.tools.ovumcy = with lib; {
    enable = mkEnableOption "Enable Ovumcy";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      ovumcy-env.file = ../../../../../secrets/ovumcy-env.age;
      # OIDC_CLIENT_ID
      # OIDC_CLIENT_SECRET
      # SECRET_KEY
    };

    virtualisation.oci-containers.containers.ovumcy = {
      image = "ghcr.io/ovumcy/ovumcy-web:v0.8.5";
      user = "${toString oci-uids.ovumcy}:${toString oci-uids.ovumcy}";
      ports = [ "${addresses.localhost}:${toString ports.ovumcy}:${toString ports.ovumcy}" ];
      volumes = [
        "/var/lib/ovumcy/data:/app/data"
      ];
      environment = {
        PORT = toString ports.ovumcy;
        TZ = timeZone;
        DB_DRIVER = "sqlite";
        DB_PATH = "/app/data/ovumcy.db";
        COOKIE_SECURE = "true";
        TRUST_PROXY_ENABLED = "true";
        PROXY_HEADER = "X-Forwarded-For";
        TRUSTED_PROXIES = "${addresses.localhost},${addresses.localhost-v6}";

        # pocket id support currently on hold; waiting on:
        # https://github.com/pocket-id/pocket-id/pull/1360
        # OIDC_ENABLED = "true";
        OIDC_ISSUER_URL = "https://${endpoints.oidc-issuer}";
        OIDC_REDIRECT_URL = "https://${fqdn}/auth/oidc/callback";
        OIDC_AUTO_PROVISION = "true";
        OIDC_LOGIN_MODE = "hybrid";
      };
      environmentFiles = [ config.age.secrets.ovumcy-env.path ];
      extraOptions = [ "--tmpfs=/tmp" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    users = mkOciUser "ovumcy";

    systemd.tmpfiles.rules = [
      "d /var/lib/ovumcy/data 0700 ${toString oci-uids.ovumcy} ${toString oci-uids.ovumcy} - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.ovumcy;
    };
  };
}
