{ config, lib, ... }:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.custom.selfhost.monit;
  fqdn = "${subdomains.${config.networking.hostName}.monit}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    services = {
      monit = {
        enable = true;
        config = ''
          set daemon 60
          set logfile syslog
          set httpd port ${toString ports.monit}
            allow ${addresses.localhost}

          check filesystem filesystem with path /
            if space usage > 90% then alert

          check process monit matching "monit"
            if does not exist then alert

          check process nginx matching "nginx"
            if does not exist then alert
        '';
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.monit}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
