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
  cfg = config.custom.services.apps.security.pocketid;
  fqdn = "${subdomains.${config.networking.hostName}.pocketid}.${domains.home}";
in
{
  options.custom.services.apps.security.pocketid = with lib; {
    enable = mkEnableOption "PocketID authentication service";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      pocketid-encryption-key.file = ../../../../../secrets/pocketid-encryption-key.age;
    };

    services = {
      pocket-id = {
        enable = true;
        settings = {
          APP_URL = "https://${fqdn}";
          PORT = ports.pocketid;
          TRUST_PROXY = true;
          ANALYTICS_DISABLED = true;
        };
        credentials = {
          ENCRYPTION_KEY = config.age.secrets.pocketid-encryption-key.path;
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.pocketid;
      };
    };
  };
}
