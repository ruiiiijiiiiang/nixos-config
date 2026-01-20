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
  inherit (helpers) mkFullExtraHosts mkVirtualHost;
  cfg = config.custom.services.networking.dns;
  fqdn = "${subdomains.${config.networking.hostName}.pihole}.${domains.home}";
in
{
  options.custom.services.networking.dns = with lib; {
    enable = mkEnableOption "Unbound + Pi-hole DNS filtering";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The network interface for DNS and VIP.";
    };

    vrrp = {
      enable = mkEnableOption "VRRP High Availability";
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
        assertion = cfg.interface != null;
        message = "Interface for DNS is missing.";
      }
    ];

    networking = {
      nameservers = [ addresses.localhost ];
      extraHosts = mkFullExtraHosts;

      firewall = {
        extraInputRules = lib.mkIf cfg.vrrp.enable ''
          ip protocol vrrp accept
        '';
        interfaces."${cfg.interface}" = {
          allowedTCPPorts = [ ports.dns ];
          allowedUDPPorts = [ ports.dns ];
        };
      };
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

      keepalived = lib.mkIf cfg.vrrp.enable {
        enable = true;

        vrrpScripts.check_dns_health = {
          script = toString (
            pkgs.writeShellScript "check_dns_health" ''
              export PATH="${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.dnsutils}/bin"
              DOMAINS=("google.com" "cloudflare.com" "microsoft.com" "amazon.com")
              for DOMAIN in "''${DOMAINS[@]}"; do
                RESULT=$(dig @127.0.0.1 "$DOMAIN" A +short +time=1 +tries=1 2>/dev/null)
                FIRST_LINE=$(echo "$RESULT" | head -n 1)
                if [[ -n "$FIRST_LINE" ]] && [[ "$FIRST_LINE" =~ ^[0-9.]+$ ]]; then
                  exit 0
                fi
              done
              exit 1
            ''
          );
          interval = 5;
          weight = -20;
          fall = 2;
          rise = 2;
        };

        vrrpInstances.dns_ha = {
          inherit (cfg) interface;
          inherit (cfg.vrrp) state priority;
          virtualRouterId = 53;
          virtualIps = [
            { addr = addresses.home.vip.dns; }
          ];
          trackScripts = [ "check_dns_health" ];
          unicastSrcIp = addresses.home.hosts.${config.networking.hostName};
          unicastPeers =
            let
              allNodes = [
                addresses.home.hosts.vm-network
                addresses.home.hosts.pi
                addresses.home.hosts.pi-legacy
              ];
            in
            builtins.filter (ip: ip != config.services.keepalived.vrrpInstances.dns_ha.unicastSrcIp) allNodes;
        };
      };
    };

    systemd.services.pihole-ftl.restartTriggers = [
      config.networking.extraHosts
    ];

    users.users.keepalived_script = lib.mkIf cfg.vrrp.enable {
      isSystemUser = true;
      group = "keepalived_script";
      description = "User for Keepalived health checks";
    };

    users.groups.keepalived_script = lib.mkIf cfg.vrrp.enable { };
  };
}
