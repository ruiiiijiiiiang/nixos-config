{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.selfhost.atuin;
  fqdn = "${subdomains.${config.networking.hostName}.atuin}.${domains.home}";
in
{
  config = mkIf cfg.enable {
    services = {
      atuin = {
        enable = true;
        openFirewall = false;
        port = ports.atuin;
        host = addresses.localhost;
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

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.atuin}";
        };
      };
    };
  };
}
