{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts) domains subdomains ports;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.selfhost.pocketid;
  fqdn = "${subdomains.${config.networking.hostName}.pocketid}.${domains.home}";
in
{
  options.custom.selfhost.pocketid = with lib; {
    enable = mkEnableOption "PocketID authentication service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      oauth2-env.file = ../../../secrets/oauth2-env.age;
    };

    services = {
      pocket-id = {
        enable = true;
        settings = {
          APP_URL = "https://${fqdn}";
          PORT = ports.pocketid;
          TRUST_PROXY = true;
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.pocketid;
      };
    };
  };
}
