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
  cfg = config.custom.services.apps.tools.searxng;
  fqdn = "${subdomains.${config.networking.hostName}.searxng}.${domains.home}";
in
{
  options.custom.services.apps.tools.searxng = with lib; {
    enable = mkEnableOption "SearXNG search engine";
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
