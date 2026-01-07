{
  config,
  lib,
  consts,
  utilFns,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.selfhost.scanopy;
  fqdn = "${subdomains.${config.networking.hostName}.scanopy}.${domains.home}";
in
{
  config = mkIf cfg.enable {
    age.secrets = {
      scanopy-env.file = ../../../secrets/scanopy-env.age;
    };

    virtualisation.oci-containers.containers = {
      scanopy-daemon = {
        image = "ghcr.io/scanopy/scanopy/daemon:latest";
        volumes = [
          "scanopy-daemon-config:/root/.config/daemon"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        environmentFiles = [ config.age.secrets.scanopy-env.path ];
        environment = {
          SCANOPY_SERVER_URL = "http://${addresses.localhost}:${toString ports.scanopy.server}";
          SCANOPY_PORT = toString ports.scanopy.daemon;
          SCANOPY_BIND_ADDRESS = addresses.any;
          SCANOPY_NAME = "scanopy-daemon";
          SCANOPY_HEARTBEAT_INTERVAL = "30";
          SCANOPY_MODE = "Push";
        };
        networks = [ "host" ];
        privileged = true;
        extraOptions = [
          "--pull=always"
        ];
      };

      scanopy-postgres = {
        image = "postgres:17-alpine";
        ports = [
          "${addresses.localhost}:${toString ports.scanopy.server}:${toString ports.scanopy.server}"
        ];
        environment = {
          POSTGRES_DB = "scanopy";
          POSTGRES_USER = "postgres";
        };
        environmentFiles = [ config.age.secrets.scanopy-env.path ];
        volumes = [ "scanopy-postgres-data:/var/lib/postgresql/data" ];
      };

      scanopy-server = {
        image = "ghcr.io/scanopy/scanopy/server:latest";
        volumes = [ "scanopy-data:/data" ];
        environment = {
          SCANOPY_WEB_EXTERNAL_PATH = "/app/static";
          SCANOPY_PUBLIC_URL = "https://${fqdn}";
          SCANOPY_INTEGRATED_DAEMON_URL = "http://${addresses.localhost}:${toString ports.scanopy.daemon}";
        };
        environmentFiles = [ config.age.secrets.scanopy-env.path ];
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
  };
}
