{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    domains
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkVirtualHost mkOciUser;
  cfg = config.custom.services.observability.scanopy.server;
  fqdn = "${subdomains.${config.networking.hostName}.scanopy}.${domains.home}";
in
{
  options.custom.services.observability.scanopy.server = with lib; {
    enable = mkEnableOption "Scanopy server";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      scanopy-server-env.file = ../../../../secrets/scanopy/server-env.age;
      # POSTGRES_DB
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # SCANOPY_DATABASE_URL
      # SCANOPY_OIDC_PROVIDERS
    };

    virtualisation.oci-containers.containers = {
      scanopy-postgres = {
        image = "postgres:17-alpine";
        ports = [
          "${toString ports.scanopy.server}:${toString ports.scanopy.server}"
        ];
        environmentFiles = [ config.age.secrets.scanopy-server-env.path ];
        volumes = [ "/var/lib/scanopy/postgres:/var/lib/postgresql/data" ];
      };

      scanopy-server = {
        image = "ghcr.io/scanopy/scanopy/server:latest";
        user = "${toString oci-uids.scanopy}:${toString oci-uids.scanopy}";
        environment = {
          SCANOPY_WEB_EXTERNAL_PATH = "/app/static";
          SCANOPY_PUBLIC_URL = "https://${fqdn}";
        };
        environmentFiles = [ config.age.secrets.scanopy-server-env.path ];
        volumes = [ "/var/lib/scanopy/data:/data" ];
        dependsOn = [ "scanopy-postgres" ];
        networks = [ "container:scanopy-postgres" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "scanopy";

    systemd.tmpfiles.rules = [
      "d /var/lib/scanopy/postgres 0700 ${toString oci-uids.postgres-alpine} ${toString oci-uids.postgres-alpine} - -"
      "d /var/lib/scanopy/data 0700 ${toString oci-uids.scanopy} ${toString oci-uids.scanopy} - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.scanopy.server;
    };

    networking.firewall.allowedTCPPorts = [ ports.scanopy.server ];
  };
}
