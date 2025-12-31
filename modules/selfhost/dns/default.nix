{ lib, config, ... }:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.selfhost.dns;
  fqdn = "${subdomains.${config.networking.hostName}.pihole}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
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
        lists = [
          {
            url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/multi.txt";
            description = "HaGeZi normal";
          }
          {
            url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
            description = "Steven Black";
          }
          {
            url = "https://v.firebog.net/hosts/AdguardDNS.txt";
            description = "AdguardDNS";
          }
          {
            url = "https://v.firebog.net/hosts/Easyprivacy.txt";
            description = "Easyprivacy";
          }
          {
            url = "https://v.firebog.net/hosts/Admiral.txt";
            description = "Admiral";
          }
          {
            url = "https://adaway.org/hosts.txt";
            description = "adaway";
          }
        ];
      };

      pihole-web = {
        enable = true;
        hostName = fqdn;
        ports = [ "${addresses.localhost}:${toString ports.pihole}o" ];
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.pihole}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
