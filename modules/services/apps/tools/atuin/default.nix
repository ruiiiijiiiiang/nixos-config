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
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.atuin;
  fqdn = "${subdomains.${config.networking.hostName}.atuin}.${domains.home}";
in
{
  options.custom.services.apps.tools.atuin = with lib; {
    enable = mkEnableOption "Atuin shell history sync server";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      atuin-env.file = ../../../../../secrets/atuin-env.age;
      # ATUIN_DB_URI
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # POSTGRES_DB
    };

    virtualisation.oci-containers.containers = {
      atuin-postgres = {
        image = "postgres:14";
        ports = [ "${addresses.localhost}:${toString ports.atuin}:${toString ports.atuin}" ];
        environmentFiles = [ config.age.secrets.atuin-env.path ];
        volumes = [ "/var/lib/atuin/postgres:/var/lib/postgresql/data" ];
      };

      atuin-server = {
        image = "ghcr.io/atuinsh/atuin:latest";
        user = "${toString oci-uids.atuin}:${toString oci-uids.atuin}";
        dependsOn = [ "atuin-postgres" ];
        networks = [ "container:atuin-postgres" ];
        environment = {
          ATUIN_HOST = addresses.any;
          ATUIN_PORT = toString ports.atuin;
        };
        environmentFiles = [ config.age.secrets.atuin-env.path ];
        volumes = [ "/var/lib/atuin/config:/config" ];
        cmd = [
          "server"
          "start"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "atuin";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/atuin/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
        "d /var/lib/atuin/config 0700 ${toString oci-uids.atuin} ${toString oci-uids.atuin} - -"
      ];

      services.podman-atuin-postgres = mkNotifyService { };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.atuin;
    };
  };
}
