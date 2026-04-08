{
  config,
  lib,
  consts,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.security.krawl;
  fqdn = "${subdomains.${config.networking.hostName}.krawl}.${domain}";
in
{
  options.custom.services.security.krawl = with lib; {
    enable = mkEnableOption "Enable Krawl";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      krawl-env.file = ../../../../secrets/krawl-env.age;
      # KRAWL_DASHBOARD_PASSWORD
    };

    virtualisation.oci-containers.containers = {
      krawl = {
        image = "ghcr.io/blessedrebus/krawl:latest";
        ports = [ "${addresses.localhost}:${toString ports.krawl}:5000" ];
        volumes = [ "/var/lib/krawl:/app/data" ];
        user = "${toString oci-uids.krawl}:${toString oci-uids.krawl}";
        environment = {
          KRAWL_DASHBOARD_SECRET_PATH = "/krawl-honeypot-dashboard";
        };
        environmentFiles = [ config.age.secrets.krawl-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "krawl";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/krawl 0700 ${toString oci-uids.krawl} ${toString oci-uids.krawl} - -"
      ];
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.krawl;
      };
    };
  };
}
