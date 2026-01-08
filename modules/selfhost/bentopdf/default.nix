{ config, lib, ... }:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.custom.selfhost.bentopdf;
  fqdn = "${subdomains.${config.networking.hostName}.bentopdf}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      bentopdf = {
        image = "bentopdf/bentopdf:latest";
        ports = [ "${addresses.localhost}:${toString ports.bentopdf}:${toString ports.bentopdf}" ];
        extraOptions = [ "--pull=always" ];
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
