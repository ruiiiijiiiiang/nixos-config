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
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.office.memos;
  fqdn = "${subdomains.${config.networking.hostName}.memos}.${domains.home}";
in
{
  options.custom.services.apps.office.memos = with lib; {
    enable = mkEnableOption "Memos notes";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      memos-env.file = ../../../../../secrets/memos-env.age;
      # POSTGRES_DB
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # MEMOS_DSN
    };

    virtualisation.oci-containers.containers = {
      memos-postgres = {
        image = "postgres:15";
        ports = [ "${addresses.localhost}:${toString ports.memos}:${toString ports.memos}" ];
        environmentFiles = [ config.age.secrets.memos-env.path ];
        volumes = [ "/var/lib/memos/postgres:/var/lib/postgresql/data" ];
      };

      memos-app = {
        image = "docker.io/neosmemo/memos:stable";
        user = "${toString oci-uids.memos}:${toString oci-uids.memos}";
        dependsOn = [ "memos-postgres" ];
        networks = [ "container:memos-postgres" ];
        environment = {
          MEMOS_DRIVER = "postgres";
        };
        environmentFiles = [ config.age.secrets.memos-env.path ];
        volumes = [ "/var/lib/memos/app:/var/opt/memos" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "memos";

    systemd.tmpfiles.rules = [
      "d /var/lib/memos/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
      "d /var/lib/memos/app 0700 ${toString oci-uids.memos} ${toString oci-uids.memos} - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.memos;
    };
  };
}
