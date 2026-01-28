{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    oidc-issuer
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.tools.karakeep;
  fqdn = "${subdomains.${config.networking.hostName}.karakeep}.${domains.home}";
in
{
  options.custom.services.apps.tools.karakeep = with lib; {
    enable = mkEnableOption "Karakeep service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      karakeep-env.file = ../../../../../secrets/karakeep-env.age;
      # OAUTH_CLIENT_ID
      # OAUTH_CLIENT_SECRET
      # OAUTH_WELLKNOWN_URL
      # NEXTAUTH_SECRET
      # MEILI_MASTER_KEY
    };

    virtualisation.oci-containers.containers = {
      karakeep-server = {
        image = "ghcr.io/karakeep-app/karakeep:release";
        ports = [ "${addresses.localhost}:${toString ports.karakeep}:3000" ];
        volumes = [ "/var/lib/karakeep:/data" ];
        environment = {
          PUID = toString oci-uids.karakeep;
          GUID = toString oci-uids.karakeep;
          NEXTAUTH_URL = "https://${fqdn}";
          MEILI_ADDR = "http://${addresses.localhost}:7700";
          BROWSER_WEB_URL = "http://${addresses.localhost}:9222";
          DATA_DIR = "/data";
          OAUTH_PROVIDER_NAME = "Pocket ID";
          OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
          OAUTH_WELLKNOWN_URL = "https://${oidc-issuer}/.well-known/openid-configuration";
        };
        environmentFiles = [ config.age.secrets.karakeep-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      karakeep-chrome = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        user = "${toString oci-uids.karakeep}:${toString oci-uids.karakeep}";
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
        user = "${toString oci-uids.karakeep}:${toString oci-uids.karakeep}";
        dependsOn = [ "karakeep-server" ];
        networks = [ "container:karakeep-server" ];
        environment = {
          MEILI_NO_ANALYTICS = "true";
        };
        environmentFiles = [ config.age.secrets.karakeep-env.path ];
        extraOptions = [
          "--tmpfs=/meili_data:rw,mode=0777"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "karakeep";

    systemd.tmpfiles.rules = [
      "d /var/lib/karakeep 0700 ${toString oci-uids.karakeep} ${toString oci-uids.karakeep} - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.karakeep;
      };
    };
  };
}
