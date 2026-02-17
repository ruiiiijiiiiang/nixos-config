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
  cfg = config.custom.services.apps.development.forgejo;
  fqdn = "${subdomains.${config.networking.hostName}.forgejo}.${domains.home}";
in
{
  options.custom.services.apps.development.forgejo = with lib; {
    enable = mkEnableOption "Forgejo version control";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      forgejo-env.file = ../../../../../secrets/forgejo-env.age;
      # POSTGRES_DB
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # FORGEJO__DATABASE__NAME
      # FORGEJO__DATABASE__USER
      # FORGEJO__DATABASE__PASSWD
      # GITEA_RUNNER_REGISTRATION_TOKEN
    };

    virtualisation.oci-containers.containers = {
      forgejo-postgres = {
        image = "docker.io/library/postgres:14";
        ports = [
          "${addresses.localhost}:${toString ports.forgejo.server}:${toString ports.forgejo.server}"
          "${
            addresses.infra.hosts.${config.networking.hostName}
          }:${toString ports.forgejo.server}:${toString ports.forgejo.server}"
          "${
            addresses.infra.hosts.${config.networking.hostName}
          }:${toString ports.forgejo.ssh}:${toString ports.forgejo.ssh}"
        ];
        environmentFiles = [ config.age.secrets.forgejo-env.path ];
        volumes = [ "/var/lib/forgejo/postgres:/var/lib/postgresql/data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
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
          HTTP_PORT = toString ports.forgejo.server;
          FORGEJO__SERVER__ROOT_URL = "https://${fqdn}";
          FORGEJO__DATABASE__DB_TYPE = "postgres";
          FORGEJO__DATABASE__HOST = "${addresses.localhost}:5432";
          FORGEJO__PACKAGE__ENABLED = "true";
          FORGEJO__PACKAGE__STORAGE_TYPE = "local";
          FORGEJO__PACKAGE__PACKAGES_PATH = "data/packages";
        };
        environmentFiles = [ config.age.secrets.forgejo-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      "forgejo-runner" = {
        image = "docker.io/gitea/act_runner:latest";
        user = "${toString oci-uids.forgejo}:${toString oci-uids.forgejo}";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "/var/lib/forgejo/runner:/data"
          "/var/lib/forgejo/cache:/.cache"
        ];
        environment = {
          GITEA_INSTANCE_URL = "http://${
            addresses.infra.hosts.${config.networking.hostName}
          }:${toString ports.forgejo.server}";
          GITEA_RUNNER_NAME = "forgejo-runner";
        };
        environmentFiles = [ config.age.secrets.forgejo-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        extraOptions = [
          "--group-add=${toString oci-uids.podman}"
        ];
      };
    };

    users = mkOciUser "forgejo";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/forgejo/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
        "d /var/lib/forgejo/data 0700 ${toString oci-uids.forgejo} ${toString oci-uids.forgejo} - -"
        "d /var/lib/forgejo/conf 0700 ${toString oci-uids.forgejo} ${toString oci-uids.forgejo} - -"
        "d /var/lib/forgejo/runner 0700 ${toString oci-uids.forgejo} ${toString oci-uids.forgejo} - -"
        "d /var/lib/forgejo/cache 0700 ${toString oci-uids.forgejo} ${toString oci-uids.forgejo} - -"
      ];

      services.podman-forgejo-postgres = mkNotifyService { };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.forgejo.server;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout 600s;
        '';
      };
    };
  };
}
