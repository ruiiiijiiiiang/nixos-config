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
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.web.searxng;
  fqdn = "${subdomains.${config.networking.hostName}.searxng}.${domain}";
in
{
  options.custom.services.apps.web.searxng = with lib; {
    enable = mkEnableOption "Enable SearXNG";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      searxng = {
        image = "docker.io/searxng/searxng:latest";
        user = "${toString oci-uids.searxng}:${toString oci-uids.searxng}";
        ports = [ "${addresses.localhost}:${toString ports.searxng}:8080" ];
        volumes = [
          "/var/lib/searxng/config/:/etc/searxng/"
          "/var/lib/searxng/data/:/var/cache/searxng/"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "searxng";

    systemd.tmpfiles.rules = [
      "d /var/lib/searxng/config 0700 ${toString oci-uids.searxng} ${toString oci-uids.searxng} - -"
      "d /var/lib/searxng/data 0700 ${toString oci-uids.searxng} ${toString oci-uids.searxng} - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.searxng;
      };
    };
  };
}
