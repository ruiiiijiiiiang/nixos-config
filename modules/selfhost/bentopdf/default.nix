{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.bentopdf;
  fqdn = "${consts.subdomains.${config.networking.hostName}.bentopdf}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      bentopdf = {
        image = "bentopdf/bentopdf:latest";
        ports = [ "${toString ports.bentopdf}:${toString ports.bentopdf}" ];
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
