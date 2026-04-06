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
    domain
    endpoints
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.networking.dns;
  fqdn = "${subdomains.${config.networking.hostName}.pihole}.${domain}";

  getFullExtraHosts =
    let
      inherit (lib)
        concatStringsSep
        mapAttrsToList
        concatMap
        filter
        attrValues
        ;
      hostFqdns = hostName: map (sub: "${sub}.${domain}") (attrValues (subdomains.${hostName} or { }));
      hostEntry =
        hostName: ip:
        let
          fqdns = hostFqdns hostName;
        in
        if fqdns == [ ] then "" else "${ip} ${concatStringsSep " " fqdns}";
      generatedEntries = concatMap (network: mapAttrsToList hostEntry addresses.${network}.hosts) [
        "infra"
      ];
      manualEntries = [
        "${addresses.home.hosts.vm-network} ${endpoints.vpn-server}"
      ];
    in
    concatStringsSep "\n" (filter (s: s != "") (generatedEntries ++ manualEntries));
in
{
  options.custom.services.networking.dns = with lib; {
    enable = mkEnableOption "Enable Unbound + Pi-hole DNS";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface name for DNS and VIP.";
    };

    vrrp = {
      enable = mkEnableOption "Enable VRRP high availability";
      state = mkOption {
        type = types.enum [
          "MASTER"
          "BACKUP"
        ];
        default = "BACKUP";
        description = "Initial VRRP state (MASTER or BACKUP).";
      };
      priority = mkOption {
        type = types.int;
        default = 90;
        description = "VRRP priority (higher wins).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.interface != null;
        message = "DNS requires interface.";
      }
      {
        assertion = (!cfg.vrrp.enable) || (cfg.vrrp.priority >= 1 && cfg.vrrp.priority <= 254);
        message = "DNS VRRP priority must be between 1 and 254.";
      }
      {
        assertion = (!cfg.vrrp.enable) || builtins.hasAttr config.networking.hostName addresses.infra.hosts;
        message = "DNS VRRP requires hostName to exist in addresses.infra.hosts.";
      }
    ];

    networking = {
      nameservers = [ addresses.localhost ];
      extraHosts = getFullExtraHosts;

      firewall = {
        # This rule can be replaced by `services.keepalived.openFirewall = true;` once the following PR is merged:
        # https://github.com/NixOS/nixpkgs/pull/457523
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

            private-domain = [ domain ];
            domain-insecure = [ domain ];
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
            pkgs.writeShellScriptBin "check_dns_health" /* bash */ ''
              export PATH="${
                pkgs.lib.makeBinPath (
                  with pkgs;
                  [
                    coreutils
                    gnugrep
                    dnsutils
                  ]
                )
              }:$PATH"
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
            { addr = addresses.infra.vip.dns; }
          ];
          trackScripts = [ "check_dns_health" ];
          unicastSrcIp = addresses.infra.hosts.${config.networking.hostName};
          unicastPeers =
            let
              allNodes = [
                addresses.infra.hosts.vm-network
                addresses.infra.hosts.pi
                addresses.infra.hosts.pi-legacy
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
