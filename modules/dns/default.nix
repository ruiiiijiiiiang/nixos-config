{ lib, config, ... }:
with lib;
let
  cfg = config.rui.dns;
  consts = import ../../lib/consts.nix;
in with consts; {
  config = mkIf cfg.enable {
    networking = {
      nameservers = [ addresses.localhost ];
    };

    services = {
      unbound = {
        enable = true;
        settings = {
          server = {
            interface = [ addresses.localhost ];
            port = ports.unbound;
            access-control = [ "${addresses.localhost}/8 allow" ];

            qname-minimisation = true;
            prefetch = true;
            prefetch-key = true;
            do-not-query-localhost = false;
            hide-identity = true;
            hide-version = true;

            private-domain = [ domains.home ];
            domain-insecure = [ domains.home ];
            local-zone = [ "${domains.home}. always_nxdomain" ];
          };

          forward-zone = [
            {
              name = ".";
              forward-tls-upstream = true;
              forward-addr = [
                "9.9.9.9@853#dns.quad9.net"
                "149.112.112.112@853#dns.quad9.net"
              ];
            }
          ];
        };
      };

      resolved.enable = false;

      pihole-ftl = {
        enable = true;
        openFirewallDNS = true;
        settings = {
          dns = {
            upstreams = [ "${addresses.localhost}#${toString ports.unbound}" ];
            listeningMode = "ALL";
          };
          privacy.privacyLevel = 0;
          dns.rateLimit = {
            count = 0;
            interval = 0;
          };
        };
      };

      pihole-web = {
        enable = true;
        hostName = "pihole.${domains.home}";
        ports = [ "${addresses.localhost}:${toString ports.pihole}o" ];
      };

      nginx.virtualHosts."pihole.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.pihole}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
