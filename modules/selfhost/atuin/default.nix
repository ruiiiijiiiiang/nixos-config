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
  cfg = config.custom.selfhost.atuin;
  fqdn = "${subdomains.${config.networking.hostName}.atuin}.${domains.home}";
in
{
  options.custom.selfhost.atuin = with lib; {
    enable = mkEnableOption "Atuin shell history sync server";
  };

  config = lib.mkIf cfg.enable {
    services = {
      atuin = {
        enable = true;
        openFirewall = false;
        port = ports.atuin;
        maxHistoryLength = 100000;
        openRegistration = true;
        database = {
          createLocally = true;
          uri = "postgresql:///atuin?host=/run/postgresql";
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = [ "atuin" ];
        ensureUsers = [
          {
            name = "atuin";
            ensureDBOwnership = true;
          }
        ];
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.atuin;
      };
    };
  };
}
