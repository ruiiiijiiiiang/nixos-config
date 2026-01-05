{
  config,
  lib,
  utilFns,
  ...
}:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.selfhost.karakeep;
  fqdn = "${subdomains.${config.networking.hostName}.karakeep}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      karakeep-env.file = ../../../secrets/karakeep-env.age;
    };

    virtualisation.oci-containers.containers = {
      karakeep-server = {
        image = "ghcr.io/karakeep-app/karakeep:release";
        ports = [ "${addresses.localhost}:${toString ports.karakeep}:3000" ];
        volumes = [ "/var/lib/karakeep:/data" ];
        environment = {
          MEILI_ADDR = "http://localhost:7700";
          NEXTAUTH_URL = "https://${fqdn}";
          BROWSER_WEB_URL = "http://localhost:9222";
          DATA_DIR = "/data";
          OAUTH_PROVIDER_NAME = "Pocket ID";
          OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
        };
        environmentFiles = [ config.age.secrets.karakeep-env.path ];
        extraOptions = [ "--pull=always" ];
      };

      karakeep-chrome = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        dependsOn = [ "karakeep" ];
        networks = [ "container:karakeep" ];
        cmd = [
          "--no-sandbox"
          "--disable-gpu"
          "--disable-dev-shm-usage"
          "--remote-debugging-address=0.0.0.0"
          "--remote-debugging-port=9222"
          "--hide-scrollbars"
        ];
      };

      karakeep-meilisearch = {
        image = "getmeili/meilisearch:latest";
        dependsOn = [ "karakeep" ];
        networks = [ "container:karakeep" ];
        volumes = [ "/var/lib/meilisearch:/meili_data" ];
        environment = {
          MEILI_NO_ANALYTICS = "true";
        };
        environmentFiles = [ config.age.secrets.karakeep-env.path ];
        extraOptions = [ "--pull=always" ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/karakeep 0750 karakeep karakeep -"
      "d /var/lib/meilisearch 0750 karakeep karakeep -"
    ];

    users.groups.karakeep = { };
    users.users.karakeep = {
      isSystemUser = true;
      group = "karakeep";
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.karakeep;
        proxyWebsockets = true;
      };
    };
  };
}
