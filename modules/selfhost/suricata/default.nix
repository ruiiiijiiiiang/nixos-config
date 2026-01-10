{
  config,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.selfhost.suricata;
  fqdn = "${subdomains.${config.networking.hostName}.evebox}.${domains.home}";
  eveJsonPath = "/var/log/suricata/eve.json";
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "Router is enabled but required interfaces are missing.";
      }
    ];

    environment.systemPackages = [ pkgs.ethtool ];

    networking = {
      localCommands = ''
        ${pkgs.ethtool}/bin/ethtool -K ${cfg.wanInterface} gro off lro off || true
        ${pkgs.ethtool}/bin/ethtool -K ${cfg.lanInterface} gro off lro off || true
      '';

      nftables = {
        enable = true;
        tables = {
          "suricata-ips" = {
            family = "inet";
            content = ''
              chain forward {
                # Hook into the FORWARD path (traffic passing through the router)
                # Priority 0 puts it alongside standard filter rules.
                type filter hook forward priority 0; policy accept;

                # 1. Forward traffic FROM WAN to LAN -> Queue 0
                iifname "${cfg.wanInterface}" oifname "${cfg.lanInterface}" counter queue num 0 bypass

                # 2. Forward traffic FROM LAN to WAN -> Queue 0
                iifname "${cfg.lanInterface}" oifname "${cfg.wanInterface}" counter queue num 0 bypass
              }
            '';
          };
        };
      };

      firewall.interfaces.${cfg.lanInterface}.allowedTCPPorts = [ ports.evebox ];
    };

    services = {
      suricata = {
        enable = true;
        disabledRules = [
          "re:modbus"
          "re:dnp3"
          "re:enip"
        ];
        settings = {
          nfq = [
            {
              mode = "accept";
              repeat-mark = 1;
              repeat-mask = 1;
              route-queue = 1;
              batchcount = 20;
            }
          ];

          af-packet = [
            {
              interface = cfg.wanInterface;
              cluster-id = 98;
              cluster-type = "cluster_flow";
              defrag = "yes";
              use-mmap = "yes";
              tpacket-v3 = "yes";
            }
            {
              interface = cfg.lanInterface;
              cluster-id = 99;
              cluster-type = "cluster_flow";
              defrag = "yes";
              use-mmap = "yes";
              tpacket-v3 = "yes";
            }
          ];

          vars = {
            address-groups = {
              HOME_NET = "[${addresses.home.network}]";
              EXTERNAL_NET = "!$HOME_NET";
            };
          };

          outputs = [
            {
              fast = {
                enabled = true;
                filename = "fast.log";
                append = true;
              };
            }
            {
              eve-log = {
                enabled = true;
                filetype = "regular";
                filename = eveJsonPath;
                file-mode = "0644";
                types = [
                  "alert"
                  "drop"
                  "dns"
                  "http"
                  "tls"
                  "flow"
                ];
              };
            }
          ];

          unix-command = {
            enabled = true;
            filename = "/run/suricata/suricata-command.socket";
          };
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.evebox;
      };
    };

    virtualisation.oci-containers.containers.evebox = {
      image = "jasonish/evebox:latest";
      ports = [ "${addresses.localhost}:${toString ports.evebox}:${toString ports.evebox}" ];
      volumes = [
        "${eveJsonPath}:/var/log/suricata/eve.json:ro"
        "/var/lib/evebox:/var/lib/evebox"
      ];

      cmd = [
        "evebox"
        "server"
        "--datastore"
        "sqlite"
        "--input"
        eveJsonPath
        "--host"
        "${addresses.any}"
        "--no-tls"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/evebox 0755 root root -"
    ];
  };
}
