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
    domain
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.ntfy;
  fqdn = "${subdomains.${config.networking.hostName}.ntfy}.${domain}";
in
{
  options.custom.services.observability.ntfy = with lib; {
    enable = mkEnableOption "Enable ntfy";
  };

  config = lib.mkIf cfg.enable {
    services = {
      ntfy-sh = {
        enable = true;
        settings = {
          base-url = "https://${fqdn}";
          behind-proxy = true;
          listen-http = "${addresses.localhost}:${toString ports.ntfy}";
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.ntfy;
      };
    };
  };
}
