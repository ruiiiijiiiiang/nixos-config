{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.yourls;
  fqdn = "${consts.subdomains.${config.networking.hostName}.yourls}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      yourls-env.file = ../../../secrets/yourls-env.age;
    };

    virtualisation.oci-containers.containers = {
      "yourls-db" = {
        image = "mariadb:12";
        ports = [ "${toString ports.yourls}:8080" ];
        environment = {
          MYSQL_DATABASE = "yourls";
          MYSQL_USER = "yourls";
        };
        environmentFiles = [ config.age.secrets.yourls-env.path ];
        volumes = [
          "/var/lib/yourls/mysql:/var/lib/mysql"
        ];
      };

      "yourls" = {
        image = "yourls:latest";
        dependsOn = [ "yourls-db" ];
        extraOptions = [
          "--network=container:yourls-db"
          "--pull=always"
        ];
        environment = {
          YOURLS_DB_HOST = addresses.localhost;
          YOURLS_DB_USER = "yourls";
          YOURLS_DB_NAME = "yourls";
          YOURLS_SITE = "https://${fqdn}";
        };
        environmentFiles = [ config.age.secrets.yourls-env.path ];
        volumes = [
          "/var/lib/yourls/html:/var/www/html"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/yourls/mysql 0700 999 999 - -"
      "d /var/lib/yourls/html 0755 33 33 - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = {
      useACMEHost = fqdn;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.yourls}";
      };
    };
  };
}
