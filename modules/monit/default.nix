{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.rui.monit;
  consts = import ../../lib/consts.nix;
in with consts; {
  config = mkIf cfg.enable {
    services = {
      monit = {
        enable = true;
        config = ''
          set daemon 60
          set logfile syslog
          set httpd port ${toString ports.monit}
            allow ${addresses.localhost}

          check filesystem sd_card with path /
            if space usage > 90% then alert

          check network ethernet interface end0
            if failed link then alert
            if download > 10 MB/s then alert

          check network wifi interface wlan0
            if failed link then alert
            if download > 10 MB/s then alert

          check process monit matching "monit"
            if does not exist then alert

          check process nginx matching "nginx"
            if does not exist then alert

          ${optionalString config.rui.acme.enable ''
          check program acme with path "/bin/sh -c 'if [ $(systemctl is-failed acme-${domains.home}.service) = \"failed\" ]; then exit 1; else exit 0; fi'"
            if status != 0 then alert
          check program ddns with path "/bin/sh -c 'if [ $(systemctl is-failed cloudflare-dyndns.service) = \"failed\" ]; then exit 1; else exit 0; fi'"
            if status != 0 then alert
          ''}

          ${optionalString config.rui.atuin.enable ''
          check process atuin matching "atuin"
            if does not exist then alert
          ''}

          ${optionalString config.rui.cloudflared.enable ''
          check process cloudflared matching "cloudflared"
            if does not exist then alert
          ''}

          ${optionalString config.rui.dns.enable ''
          check process pihole matching "pihole-FTL"
            if does not exist then alert
          check process unbound matching "bin/unbound"
            if does not exist then alert
          ''}

          ${optionalString config.rui.homeassistant.enable ''
          check host homeassistant address ${addresses.localhost}
            if failed port ${toString ports.homeassistant} protocol http then alert
          check host zwave address ${addresses.localhost}
            if failed port ${toString ports.zwave.server} protocol http then alert
          ''}

          ${optionalString config.rui.microbin.enable ''
          check process microbin matching "microbin"
            if does not exist then alert
          ''}

          ${optionalString config.rui.syncthing.enable ''
          check process syncthing matching "syncthing"
            if does not exist then alert
          ''}

          ${optionalString config.rui.vaultwarden.enable ''
          check process vaultwarden matching "vaultwarden"
            if does not exist then alert
          ''}
        '';
      };

      nginx.virtualHosts."monit.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.monit}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
