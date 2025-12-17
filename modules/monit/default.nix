{ config, lib, ... }:
with lib;
let
  cfg = config.selfhost.monit;
  consts = import ../../lib/consts.nix;
  fqdn = "${consts.subdomains.${config.networking.hostName}.monit}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
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

          ${optionalString config.selfhost.atuin.enable ''
            check process atuin matching "atuin"
              if does not exist then alert
          ''}

          ${optionalString config.selfhost.beszel.enable ''
            check process beszel matching "beszel"
              if does not exist then alert
          ''}

          ${optionalString config.selfhost.cloudflared.enable ''
            check process cloudflared matching "cloudflared"
              if does not exist then alert
          ''}

          ${optionalString config.selfhost.dns.enable ''
            check process pihole matching "pihole-FTL"
              if does not exist then alert
            check process unbound matching "bin/unbound"
              if does not exist then alert
          ''}

          ${optionalString config.selfhost.microbin.enable ''
            check process microbin matching "microbin"
              if does not exist then alert
          ''}

          ${optionalString config.selfhost.syncthing.enable ''
            check process syncthing matching "syncthing"
              if does not exist then alert
          ''}

          ${optionalString config.selfhost.vaultwarden.enable ''
            check process vaultwarden matching "vaultwarden"
              if does not exist then alert
          ''}

          ${optionalString config.selfhost.dyndns.enable ''
            check program dyndns with path "/bin/sh -c 'if [ $(systemctl is-failed cloudflare-dyndns.service) = \"failed\" ]; then exit 1; else exit 0; fi'"
              if status != 0 then alert
          ''}

          ${optionalString config.selfhost.homeassistant.enable ''
            check host homeassistant address ${addresses.localhost}
              if failed port ${toString ports.homeassistant} protocol http then alert
            check host zwave address ${addresses.localhost}
              if failed port ${toString ports.zwave} protocol http then alert
          ''}

          ${optionalString config.selfhost.bentopdf.enable ''
            check host bentopdf address ${addresses.localhost}
              if failed port ${toString ports.bentopdf} protocol http then alert
          ''}

          ${optionalString config.selfhost.portainer.enable ''
            check host portainer address ${addresses.localhost}
              if failed port ${toString ports.portainer.server} protocol http then alert
          ''}

          ${optionalString config.selfhost.website.enable ''
            check host website address ${addresses.localhost}
              if failed port ${toString ports.website} protocol http then alert
          ''}
        '';
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.monit}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };
}
