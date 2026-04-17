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
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.changedetection;
  fqdn = "${subdomains.${config.networking.hostName}.changedetection}.${domain}";
in
{
  options.custom.services.apps.tools.changedetection = with lib; {
    enable = mkEnableOption "Enable ChangeDetection.io";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      changedetection = {
        image = "ghcr.io/dgtlmoon/changedetection.io:latest";
        user = "${toString oci-uids.changedetection}:${toString oci-uids.changedetection}";
        ports = [ "${addresses.localhost}:${toString ports.changedetection}:5000" ];
        environment = {
          BASE_URL = "https://${fqdn}";
          PLAYWRIGHT_DRIVER_URL = "ws://${addresses.localhost}:3000";
        };
        volumes = [ "/var/lib/changedetection/data:/datastore" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      sockpuppetbrowser = {
        image = "docker.io/dgtlmoon/sockpuppetbrowser:latest";
        user = "${toString oci-uids.changedetection}:${toString oci-uids.changedetection}";
        dependsOn = [ "changedetection" ];
        networks = [ "container:changedetection" ];
        environment = {
          SCREEN_WIDTH = "1920";
          SCREEN_HEIGHT = "1080";
          SCREEN_DEPTH = "24";
          MAX_CONCURRENT_CHROME_PROCESSES = "10";
        };
        extraOptions = [ "--cap-add=SYS_ADMIN" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "changedetection";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/changedetection/data 0700 ${toString oci-uids.changedetection} ${toString oci-uids.changedetection} - -"
      ];

      services.podman-changedetection = mkNotifyService { };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.changedetection;
    };
  };
}
