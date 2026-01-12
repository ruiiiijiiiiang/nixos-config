{ config, lib, ... }:
let
  inherit (import ../../../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
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
        ports = [ "${addresses.localhost}:${toString ports.bentopdf}:${toString ports.bentopdf}" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.bentopdf}";
        };
      };
    };
  };
}
