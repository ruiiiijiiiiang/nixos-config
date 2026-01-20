{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts) domains subdomains ports;
  inherit (helpers) mkVirtualHost;
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
        autoStart = true;
        ports = [
          "${toString ports.scanopy.server}:${toString ports.scanopy.server}"
        ];
        environmentFiles = [ config.age.secrets.scanopy-server-env.path ];
        volumes = [ "scanopy-postgres-data:/var/lib/postgresql/data" ];
      };

      scanopy-server = {
        image = "ghcr.io/scanopy/scanopy/server:latest";
        autoStart = true;
        volumes = [ "scanopy-data:/data" ];
        environment = {
          SCANOPY_WEB_EXTERNAL_PATH = "/app/static";
          SCANOPY_PUBLIC_URL = "https://${fqdn}";
        };
        environmentFiles = [ config.age.secrets.scanopy-server-env.path ];
        dependsOn = [ "scanopy-postgres" ];
        networks = [ "container:scanopy-postgres" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.scanopy.server;
    };

    networking.firewall.allowedTCPPorts = [ ports.scanopy.server ];
  };
}
