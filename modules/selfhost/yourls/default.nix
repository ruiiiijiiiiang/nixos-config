{
  config,
  consts,
  lib,
  utilFns,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.custom.selfhost.yourls;
  fqdn = "${subdomains.${config.networking.hostName}.yourls}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      yourls-env.file = ../../../secrets/yourls-env.age;
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

      yourls = {
        image = "yourls:latest";
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
        extraOptions = [
          "--pull=always"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/yourls/mysql 0700 999 999 - -"
      "d /var/lib/yourls/html 0755 33 33 - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.yourls;
    };
  };
}
