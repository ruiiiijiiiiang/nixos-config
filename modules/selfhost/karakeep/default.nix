{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    id-fqdn
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.selfhost.karakeep;
  fqdn = "${subdomains.${config.networking.hostName}.karakeep}.${domains.home}";
in
{
  options.custom.selfhost.karakeep = with lib; {
    enable = mkEnableOption "Karakeep service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      karakeep-env.file = ../../../secrets/karakeep-env.age;
      # OAUTH_CLIENT_ID
      # OAUTH_CLIENT_SECRET
      # OAUTH_WELLKNOWN_URL=https://id.ruijiang.me/.well-known/openid-configuration
      # NEXTAUTH_SECRET=Z94Ztgwth0B7oHrLZqGfSdzWV3hBPqK3ZmKdfxxBnCBmq2Dp
      # MEILI_MASTER_KEY=ZULoq5lU3ccYHM3JGCEdDuIX8xgPycc03PiFo3YPFCY94
    };

    virtualisation.oci-containers.containers = {
      karakeep-server = {
        image = "ghcr.io/karakeep-app/karakeep:release";
        ports = [ "${addresses.localhost}:${toString ports.karakeep}:3000" ];
        volumes = [ "/var/lib/karakeep:/data" ];
        environment = {
          NEXTAUTH_URL = "https://${fqdn}";
          MEILI_ADDR = "http://${addresses.localhost}:7700";
          BROWSER_WEB_URL = "http://${addresses.localhost}:9222";
          DATA_DIR = "/data";
          OAUTH_PROVIDER_NAME = "Pocket ID";
          OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
          OAUTH_WELLKNOWN_URL = "https://${id-fqdn}/.well-known/openid-configuration";
        };
        environmentFiles = [ config.age.secrets.karakeep-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      karakeep-chrome = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        dependsOn = [ "karakeep-server" ];
        networks = [ "container:karakeep-server" ];
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
        image = "docker.io/getmeili/meilisearch:latest";
        dependsOn = [ "karakeep-server" ];
        networks = [ "container:karakeep-server" ];
        volumes = [ "meilisearch-data:/meili_data" ];
        environment = {
          MEILI_NO_ANALYTICS = "true";
        };
        environmentFiles = [ config.age.secrets.karakeep-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/karakeep 0750 karakeep karakeep -"
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
      };
    };
  };
}
