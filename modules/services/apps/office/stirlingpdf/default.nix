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
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.office.stirlingpdf;
  fqdn = "${subdomains.${config.networking.hostName}.stirlingpdf}.${domains.home}";
in
{
  options.custom.services.apps.office.stirlingpdf = with lib; {
    enable = mkEnableOption "Stirling-PDF document tools";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      stirling-pdf = {
        image = "docker.io/stirlingtools/stirling-pdf:latest";
        ports = [ "${addresses.localhost}:${toString ports.stirlingpdf}:${toString ports.stirlingpdf}" ];
        environment = {
          SECURITY_ENABLELOGIN = "false";
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.stirlingpdf;
    };
  };
}
