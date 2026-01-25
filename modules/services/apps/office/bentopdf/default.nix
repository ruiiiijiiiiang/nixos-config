{
  config,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.office.bentopdf;
  fqdn = "${subdomains.${config.networking.hostName}.bentopdf}.${domains.home}";
in
{
  options.custom.services.apps.office.bentopdf = with lib; {
    enable = mkEnableOption "BentoPDF PDF service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      bentopdf = {
        image = "bentopdf/bentopdf:latest";
        user = "${toString oci-uids.nobody}:${toString oci-uids.nobody}";
        ports = [ "${addresses.localhost}:${toString ports.bentopdf}:${toString ports.bentopdf}" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.bentopdf;
      };
    };
  };
}
