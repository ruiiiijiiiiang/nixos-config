{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    oci-uids
    endpoints
    ;
  inherit (helpers) mkVirtualHost mkOciUser;
  cfg = config.custom.services.observability.termix;
  fqdn = "${subdomains.${config.networking.hostName}.termix}.${domain}";
in
{
  options.custom.services.observability.termix = with lib; {
    enable = mkEnableOption "Enable Termix terminal-based dashboard";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      termix-env.file = ../../../../secrets/termix-env.age;
      # OIDC_CLIENT_ID
      # OIDC_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers.termix = {
      image = "ghcr.io/lukegus/termix";
      ports = [ "${addresses.localhost}:${toString ports.termix}:${toString ports.termix}" ];
      volumes = [ "/var/lib/termix:/app/data" ];
      environment = {
        PORT = toString ports.termix;
        PUID = toString oci-uids.termix;
        PGID = toString oci-uids.termix;
        OIDC_ISSUER_URL = "https://${endpoints.oidc-issuer}";
        OIDC_AUTHORIZATION_URL = "https://${endpoints.oidc-issuer}/authorize";
        OIDC_TOKEN_URL = "https://${endpoints.oidc-issuer}/api/oidc/token";
        OIDC_NAME_PATH = "preferred_username";
      };
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/termix 0700 ${toString oci-uids.termix} ${toString oci-uids.termix} - -"
    ];

    users = mkOciUser "termix";

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.termix;
    };
  };
}
