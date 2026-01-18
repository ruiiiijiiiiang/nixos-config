{
  config,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  inherit (import ../../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.networking.suricata;
  fqdn = "${subdomains.${config.networking.hostName}.evebox}.${domains.home}";
  eveJsonPath = "/var/log/suricata/eve.json";
in
{
  options.custom.services.networking.suricata = with lib; {
    enable = mkEnableOption "Suricata IDS/IPS";
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface connecting to the WAN";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface connecting to the LAN";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "Suricata is enabled but required interfaces are missing.";
      }
    ];

    environment.systemPackages = [ pkgs.ethtool ];

    networking = {
      localCommands = ''
        ${pkgs.ethtool}/bin/ethtool -K ${cfg.wanInterface} gro off lro off || true
        ${pkgs.ethtool}/bin/ethtool -K ${cfg.lanInterface} gro off lro off || true
      '';

      nftables.tables = {
        "suricata-ips" = {
          family = "inet";
          content = ''
            chain forward {
              # Hook into the FORWARD path (traffic passing through the router)
              # Priority 0 puts it alongside standard filter rules.
              type filter hook forward priority 0; policy accept;

              ${lib.optionalString config.custom.services.networking.wireguard.server.enable ''
                iifname ${config.custom.services.networking.wireguard.server.interface} counter return # Traffic coming from VPN
                oifname ${config.custom.services.networking.wireguard.server.interface} counter return # Traffic going to VPN
              ''}

              iifname "${cfg.wanInterface}" oifname "${cfg.lanInterface}" counter queue num 0 bypass # Forward traffic from WAN to LAN -> Queue 0
              iifname "${cfg.lanInterface}" oifname "${cfg.wanInterface}" counter queue num 0 bypass # Forward traffic from LAN to WAN -> Queue 0
            }
          '';
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

          # Dummy listener just to make nix happy
          af-packet = [
            {
              interface = "lo";
              cluster-id = 99;
              cluster-type = "cluster_flow";
              defrag = "yes";
              use-mmap = "yes";
              tpacket-v3 = "yes";
              bpf-filter = "not host 127.0.0.1";
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
              eve-log = {
                enabled = true;
                filetype = "regular";
                filename = eveJsonPath;
                file-mode = "0644";
                types = [
                  "alert"
                  "drop"
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

    virtualisation.oci-containers.containers = {
      evebox = {
        image = "docker.io/jasonish/evebox:latest";
        ports = [ "${addresses.localhost}:${toString ports.evebox}:${toString ports.evebox}" ];
        volumes = [
          "${eveJsonPath}:${eveJsonPath}:ro"
          "/var/lib/evebox:/var/lib/evebox"
        ]
        ++ lib.optional config.custom.services.networking.geoipupdate.enable "/var/lib/GeoIP:/etc/evebox/:ro";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        cmd = [
          "evebox"
          "server"
          "--datastore"
          "sqlite"
          "--input"
          eveJsonPath
          "--no-tls"
        ];
        # Run `nix-shell -p sqlite --run "sqlite3 /var/lib/evebox/events.sqlite 'PRAGMA journal_mode=WAL;'"` once to enable WAL
        # Write-Ahead Logging significantly reduces I/O load
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/evebox 0755 root root -"
    ];
  };
}
