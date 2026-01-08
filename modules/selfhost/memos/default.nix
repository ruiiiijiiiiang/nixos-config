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
  cfg = config.custom.selfhost.memos;
  fqdn = "${subdomains.${config.networking.hostName}.memos}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      memos-env.file = ../../../secrets/memos-env.age;
    };

    virtualisation.oci-containers.containers = {
      memos-db = {
        image = "postgres:15";
        ports = [ "${addresses.localhost}:${toString ports.memos}:${toString ports.memos}" ];
        environmentFiles = [ config.age.secrets.memos-env.path ];
        volumes = [ "memos-db-data:/var/lib/postgresql/data" ];
      };

      memos-app = {
        image = "neosmemo/memos:stable";
        dependsOn = [ "memos-db" ];
        networks = [ "container:memos-db" ];
        environment = {
          MEMOS_DRIVER = "postgres";
        };
        environmentFiles = [ config.age.secrets.memos-env.path ];
        volumes = [ "memos-data:/var/opt/memos" ];
        extraOptions = [ "--pull=always" ];
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.memos;
      proxyWebsockets = true;
    };
  };
}
