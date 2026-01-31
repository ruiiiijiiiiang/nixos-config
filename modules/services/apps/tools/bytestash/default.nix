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
  cfg = config.custom.services.apps.tools.bytestash;
  fqdn = "${subdomains.${config.networking.hostName}.bytestash}.${domains.home}";
in
{
  options.custom.services.apps.tools.bytestash = with lib; {
    enable = mkEnableOption "ByteStash service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      bytestash-env.file = ../../../../../secrets/bytestash-env.age;
      # JWT_SECRET
    };

    virtualisation.oci-containers.containers = {
      bytestash = {
        image = "ghcr.io/jordan-dalby/bytestash:latest";
        user = "${toString oci-uids.bytestash}:${toString oci-uids.bytestash}";
        ports = [ "${addresses.localhost}:${toString ports.bytestash}:${toString ports.bytestash}" ];
        volumes = [ "/var/lib/bytestash:/data" ];
        environment = {
          DISABLE_ACCOUNTS = "true";
        };
        environmentFiles = [ config.age.secrets.bytestash-env.path ];
        extraOptions = [ "--tmpfs=/tmp" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "bytestash";

    systemd.tmpfiles.rules = [
      "d /var/lib/bytestash 0700 ${toString oci-uids.bytestash} ${toString oci-uids.bytestash} - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.bytestash;
      };
    };
  };
}
