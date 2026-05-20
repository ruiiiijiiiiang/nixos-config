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
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.mealie;
  fqdn = "${subdomains.${config.networking.hostName}.mealie}.${domain}";
in
{
  options.custom.services.apps.tools.mealie = with lib; {
    enable = mkEnableOption "Enable Mealie";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      mealie-env.file = ../../../../../secrets/mealie-env.age;
      # OIDC_CLIENT_ID
      # OIDC_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers.mealie = {
      image = "ghcr.io/mealie-recipes/mealie:latest";
      user = "${toString oci-uids.mealie}:${toString oci-uids.mealie}";
      ports = [ "${addresses.localhost}:${toString ports.mealie}:9000" ];
      volumes = [ "/var/lib/mealie:/app/data" ];
      environment = {
        ALLOW_SIGNUP = "false";
        PUID = toString oci-uids.mealie;
        PGID = toString oci-uids.mealie;
        TZ = timeZone;
        BASE_URL = "https://${fqdn}";

        OIDC_AUTH_ENABLED = "true";
        OIDC_CONFIGURATION_URL = "https://${endpoints.oidc-issuer}/.well-known/openid-configuration";
        OIDC_PROVIDER_NAME = "Pocket ID";
      };
      environmentFiles = [ config.age.secrets.mealie-env.path ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    users = mkOciUser "mealie";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/mealie 0700 ${toString oci-uids.mealie} ${toString oci-uids.mealie} - -"
      ];

      services.podman-mealie = mkNotifyService { };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.mealie;
    };
  };
}
