{
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.pricebuddy;
  fqdn = "${subdomains.${config.networking.hostName}.pricebuddy}.${domain}";
in
{
  options.custom.services.apps.tools.pricebuddy = with lib; {
    enable = mkEnableOption "Enable PriceBuddy";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      pricebuddy-env.file = ../../../../../secrets/pricebuddy-env.age;
      # DB_USERNAME
      # DB_PASSWORD
      # DB_DATABASE
      # MYSQL_ROOT_PASSWORD
      # MYSQL_USER
      # MYSQL_PASSWORD
      # MYSQL_DATABASE
      # APP_USER_EMAIL
      # APP_USER_PASSWORD
    };

    virtualisation.oci-containers.containers = {
      pricebuddy-mysql = {
        image = "docker.io/library/mysql:8";
        ports = [ "${addresses.localhost}:${toString ports.pricebuddy}:80" ];
        volumes = [ "/var/lib/pricebuddy/mysql:/var/lib/mysql" ];
        environmentFiles = [ config.age.secrets.pricebuddy-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      pricebuddy = {
        image = "docker.io/jez500/pricebuddy:latest";
        dependsOn = [ "pricebuddy-mysql" ];
        networks = [ "container:pricebuddy-mysql" ];
        volumes = [
          "/var/lib/pricebuddy/storage:/app/storage"
        ];
        environment = {
          APP_URL = "https://${fqdn}";
          ASSET_URL = "https://${fqdn}";
          DB_HOST = addresses.localhost;
          SCRAPER_BASE_URL = "http://localhost:3000";
          AFFILIATE_ENABLED = "true";
          TRUSTED_PROXIES = "*";
        };
        environmentFiles = [ config.age.secrets.pricebuddy-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      pricebuddy-scraper = {
        image = "docker.io/jez500/seleniumbase-scrapper:latest";
        dependsOn = [ "pricebuddy-mysql" ];
        networks = [ "container:pricebuddy-mysql" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "pricebuddy";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/pricebuddy/storage 0755 ${toString oci-uids.pricebuddy} ${toString oci-uids.pricebuddy} - -"
        "d /var/lib/pricebuddy/mysql 0755 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
      ];

      services.podman-pricebuddy = mkNotifyService { };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.pricebuddy;
      extraConfig = ''
        proxy_redirect http://${fqdn}/ /;
      '';
    };
  };
}
