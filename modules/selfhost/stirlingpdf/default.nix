{
  config,
  consts,
  lib,
  utilFns,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.custom.selfhost.stirlingpdf;
  fqdn = "${subdomains.${config.networking.hostName}.stirlingpdf}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      stirling-pdf = {
        image = "docker.io/stirlingtools/stirling-pdf:latest";
        ports = [ "${addresses.localhost}:${toString ports.stirlingpdf}:${toString ports.stirlingpdf}" ];
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
