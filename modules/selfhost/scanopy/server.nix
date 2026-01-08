{
  config,
  consts,
  lib,
  utilFns,
  ...
}:
let
  inherit (consts) domains subdomains ports;
  inherit (utilFns) mkVirtualHost;
  cfg = config.custom.selfhost.scanopy.server;
  fqdn = "${subdomains.${config.networking.hostName}.scanopy}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      scanopy-server-env.file = ../../../secrets/scanopy/server-env.age;
    };

    virtualisation.oci-containers.containers = {
      scanopy-postgres = {
        image = "postgres:17-alpine";
        ports = [
          "${toString ports.scanopy.server}:${toString ports.scanopy.server}"
        ];
        environmentFiles = [ config.age.secrets.scanopy-server-env.path ];
        volumes = [ "scanopy-postgres-data:/var/lib/postgresql/data" ];
      };

      scanopy-server = {
        image = "ghcr.io/scanopy/scanopy/server:latest";
        volumes = [ "scanopy-data:/data" ];
        environment = {
          SCANOPY_WEB_EXTERNAL_PATH = "/app/static";
          SCANOPY_PUBLIC_URL = "https://${fqdn}";
        };
        environmentFiles = [ config.age.secrets.scanopy-server-env.path ];
        dependsOn = [ "scanopy-postgres" ];
        networks = [ "container:scanopy-postgres" ];
        extraOptions = [ "--pull=always" ];
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.scanopy.server;
      proxyWebsockets = true;
    };

    networking.firewall.allowedTCPPorts = [ ports.scanopy.server ];
  };
}
