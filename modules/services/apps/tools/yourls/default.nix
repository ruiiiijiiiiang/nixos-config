{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.yourls;
  fqdn = "${subdomains.${config.networking.hostName}.yourls}.${domains.home}";
in
{
  options.custom.services.apps.tools.yourls = with lib; {
    enable = mkEnableOption "YOURLS URL shortener";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      yourls-env.file = ../../../../../secrets/yourls-env.age;
      # MYSQL_DATABASE
      # MYSQL_USER
      # MYSQL_ROOT_PASSWORD
      # MYSQL_PASSWORD
      # YOURLS_USER
      # YOURLS_PASS
      # YOURLS_DB_NAME
      # YOURLS_DB_USER
      # YOURLS_DB_PASS
    };

    virtualisation.oci-containers.containers = {
      yourls-db = {
        image = "mariadb:12";
        ports = [ "${addresses.localhost}:${toString ports.yourls}:8080" ];
        environmentFiles = [ config.age.secrets.yourls-env.path ];
        volumes = [
          "/var/lib/yourls/mysql:/var/lib/mysql"
        ];
      };

      yourls-server = {
        image = "docker.io/library/yourls:latest";
        dependsOn = [ "yourls-db" ];
        networks = [ "container:yourls-db" ];
        environment = {
          YOURLS_DB_HOST = addresses.localhost;
          YOURLS_SITE = "https://${fqdn}";
        };
        environmentFiles = [ config.age.secrets.yourls-env.path ];
        volumes = [
          "/var/lib/yourls/html:/var/www/html"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/yourls/mysql 0700 999 999 - -"
        "d /var/lib/yourls/html 0755 33 33 - -"
      ];

      services.podman-yourls-db = mkNotifyService { };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.yourls;
    };
  };
}
