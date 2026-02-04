{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    username
    addresses
    domains
    subdomains
    ports
    oci-uids
    oidc-issuer
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.tools.bytestash;
  fqdn = "${subdomains.${config.networking.hostName}.bytestash}.${domains.home}";
in
{
  options.custom.services.apps.tools.bytestash = with lib; {
    enable = mkEnableOption "ByteStash code snippet stash";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      bytestash-env.file = ../../../../../secrets/bytestash-env.age;
      # JWT_SECRET
      # OIDC_CLIENT_ID
      # OIDC_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers = {
      bytestash = {
        image = "ghcr.io/jordan-dalby/bytestash:latest";
        user = "${toString oci-uids.bytestash}:${toString oci-uids.bytestash}";
        ports = [ "${addresses.localhost}:${toString ports.bytestash}:${toString ports.bytestash}" ];
        volumes = [ "/var/lib/bytestash:/data" ];
        environment = {
          ADMIN_USERNAMES = username;
          DISABLE_ACCOUNTS = "false";
          DISABLE_INTERNAL_ACCOUNTS = "true";
          OIDC_ENABLED = "true";
          OIDC_DISPLAY_NAME = "Pocket ID";
          OIDC_ISSUER_URL = "https://${oidc-issuer}";
        };
        environmentFiles = [ config.age.secrets.bytestash-env.path ];
        extraOptions = [ "--tmpfs=/tmp" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "bytestash";

    systemd.tmpfiles.rules = [
      "d /var/lib/bytestash 0700 ${toString oci-uids.bytestash} ${toString oci-uids.bytestash} - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.bytestash;
      };
    };
  };
}
