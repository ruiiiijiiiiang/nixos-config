{
  config,
  consts,
  lib,
  helpers,
  pkgs,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.networking.dns;
  fqdn = "${subdomains.${config.networking.hostName}.pihole}.${domains.home}";
in
{
  options.custom.services.networking.dns = with lib; {
    enable = mkEnableOption "Unbound + Pi-hole DNS filtering";
    vrrp = {
      interface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The network interface to bind the VIP to.";
      };
      state = mkOption {
        type = types.enum [
          "MASTER"
          "BACKUP"
        ];
        default = "BACKUP";
        description = "The initial VRRP state for this node. Must be MASTER or BACKUP.";
      };
      priority = mkOption {
        type = types.int;
        default = 90;
        description = "VRRP Priority (Higher wins). Recommended: Master=100, Backup=90/80.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.vrrp.interface != null;
        message = "Interface for High Availability is missing.";
      }
    ];

    networking = {
      nameservers = [ addresses.localhost ];
      firewall.extraInputRules = ''
        ip protocol vrrp accept
      '';
    };

    environment.systemPackages = with pkgs; [ dnsutils ];

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
        openFirewallDNS = false;
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

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.pihole;
      };

      keepalived = {
        enable = true;

        vrrpScripts.check_dns_health = {
          script = toString (
            pkgs.writeShellScript "check_dns_health" ''
              if ${pkgs.dnsutils}/bin/dig @127.0.0.1 . ns +short +time=1 +tries=1 | grep -q "."; then
                 exit 0
              fi
              exit 1
            ''
          );
          interval = 10;
          weight = -20;
          fall = 2;
          rise = 2;
        };

        vrrpInstances.dns_ha = {
          inherit (cfg.vrrp) interface state priority;
          virtualRouterId = 53;
          virtualIps = [
            { addr = addresses.home.vip.dns; }
          ];
          trackScripts = [ "check_dns_health" ];
        };
      };
    };
  };
}
