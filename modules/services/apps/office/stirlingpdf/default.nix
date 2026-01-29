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
          PUID = toString oci-uids.nobody;
          GUID = toString oci-uids.nobody;
          SECURITY_ENABLELOGIN = "false";
          JAVA_TOOL_OPTIONS = "-Xms128m -Xmx512m -XX:MaxMetaspaceSize=128m";
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        extraOptions = [
          "--memory=768m"
          "--memory-swap=768m"
        ];
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.stirlingpdf;
    };
  };
}
