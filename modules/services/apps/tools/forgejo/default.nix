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
  cfg = config.custom.services.apps.tools.forgejo;
  fqdn = "${subdomains.${config.networking.hostName}.forgejo}.${domains.home}";
in
{
  options.custom.services.apps.tools.forgejo = with lib; {
    enable = mkEnableOption "Forgejo version control";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      forgejo-env.file = ../../../../../secrets/forgejo-env.age;
      # POSTGRES_DB
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # FORGEJO__database__NAME
      # FORGEJO__database__USER
      # FORGEJO__database__PASSWD
    };

    virtualisation.oci-containers.containers = {
      forgejo-postgres = {
        image = "postgres:14";
        ports = [
          "${addresses.localhost}:${toString ports.forgejo.server}:${toString ports.forgejo.server}"
          "${
            addresses.infra.hosts.${config.networking.hostName}
          }:${toString ports.forgejo.ssh}:${toString ports.forgejo.ssh}"
        ];
        environmentFiles = [ config.age.secrets.forgejo-env.path ];
        volumes = [ "/var/lib/forgejo/postgres:/var/lib/postgresql/data" ];
      };

      forgejo-server = {
        image = "codeberg.org/forgejo/forgejo:13-rootless";
        user = "${toString oci-uids.forgejo}:${toString oci-uids.forgejo}";
        dependsOn = [ "forgejo-postgres" ];
        networks = [ "container:forgejo-postgres" ];
        volumes = [
          "/var/lib/forgejo/data:/var/lib/gitea"
          "/var/lib/forgejo/conf:/etc/gitea"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environment = {
          FORGEJO__database__DB_TYPE = "postgres";
          FORGEJO__database__HOST = "${addresses.localhost}:5432";
          HTTP_PORT = toString ports.forgejo.server;
        };
        environmentFiles = [ config.age.secrets.forgejo-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "forgejo";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/forgejo/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
        "d /var/lib/forgejo/data 0700 ${toString oci-uids.forgejo} ${toString oci-uids.forgejo} - -"
        "d /var/lib/forgejo/conf 0700 ${toString oci-uids.forgejo} ${toString oci-uids.forgejo} - -"
      ];

      services.podman-forgejo-postgres = mkNotifyService { };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.forgejo.server;
      };
    };
  };
}
