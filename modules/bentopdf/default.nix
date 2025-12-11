{ config, lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  cfg = config.rui.bentopdf;
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
      nginx.virtualHosts."pdf.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.bentopdf}";
        };
      };
    };
  };
}
