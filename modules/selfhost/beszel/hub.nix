{ config, lib, ... }:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.selfhost.beszel.hub;
  fqdn = "${subdomains.${config.networking.hostName}.beszel}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
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
