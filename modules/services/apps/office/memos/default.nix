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
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.office.memos;
  fqdn = "${subdomains.${config.networking.hostName}.memos}.${domains.home}";
in
{
  options.custom.services.apps.office.memos = with lib; {
    enable = mkEnableOption "Memos service";
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
        autoStart = true;
        ports = [ "${addresses.localhost}:${toString ports.memos}:${toString ports.memos}" ];
        environmentFiles = [ config.age.secrets.memos-env.path ];
        volumes = [ "/var/lib/memos/postgres:/var/lib/postgresql/data" ];
      };

      memos-app = {
        image = "docker.io/neosmemo/memos:stable";
        autoStart = true;
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

    users.groups.memos = {
      gid = oci-uids.memos;
    };
    users.users.memos = {
      uid = oci-uids.memos;
      group = "memos";
      isSystemUser = true;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/memos/postgres 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
      "d /var/lib/memos/app 0755 memos memos - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.memos;
    };
  };
}
