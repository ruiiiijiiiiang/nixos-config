{
  config,
  lib,
  consts,
  utilFns,
  ...
}:
let
  inherit (consts) domains subdomains ports;
  inherit (utilFns) mkVirtualHost;
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

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.beszel.hub;
        websocket = true;
      };
    };
  };
}
