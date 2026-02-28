{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts) domain subdomains ports;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.beszel.hub;
  fqdn = "${subdomains.${config.networking.hostName}.beszel}.${domain}";
in
{
  options.custom.services.observability.beszel.hub = with lib; {
    enable = mkEnableOption "Beszel monitoring hub";
  };

  config = lib.mkIf cfg.enable {
    services = {
      beszel.hub = {
        enable = true;
        port = ports.beszel.hub;
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.beszel.hub;
      };
    };
  };
}
