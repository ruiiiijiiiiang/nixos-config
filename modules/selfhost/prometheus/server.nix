{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.beszel.hub;
  fqdn = "${consts.subdomains.${config.networking.hostName}.beszel}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    services = {
      beszel.hub = {
        enable = true;
        port = ports.beszel.hub;
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.beszel.hub}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
