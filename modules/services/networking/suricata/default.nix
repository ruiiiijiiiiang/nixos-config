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
      description = "Interface for WAN";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for LAN";
    };
    infraInterface = mkOption {
      type = types.str;
      default = "infra0";
      description = "Interface for infra VLAN";
    };
    dmzInterface = mkOption {
      type = types.str;
      default = "dmz0";
      description = "Interface for DMZ VLAN";
    };
    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "Interface for WireGuard server";
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
              type filter hook forward priority -10; policy accept;

              iifname "${cfg.wanInterface}" oifname "${cfg.lanInterface}" counter queue num 0 bypass
              iifname "${cfg.lanInterface}" oifname "${cfg.wanInterface}" counter queue num 0 bypass

              iifname ${cfg.wgInterface} counter return
              oifname ${cfg.wgInterface} counter return

              iifname "${cfg.wanInterface}" oifname "${cfg.infraInterface}" counter queue num 0 bypass
              iifname "${cfg.infraInterface}" oifname "${cfg.wanInterface}" counter queue num 0 bypass
              iifname "${cfg.lanInterface}" oifname "${cfg.infraInterface}" counter queue num 0 bypass
              iifname "${cfg.infraInterface}" oifname "${cfg.lanInterface}" counter queue num 0 bypass

              iifname "${cfg.wanInterface}" oifname "${cfg.dmzInterface}" counter queue num 0 bypass
              iifname "${cfg.dmzInterface}" oifname "${cfg.wanInterface}" counter queue num 0 bypass
              iifname "${cfg.lanInterface}" oifname "${cfg.dmzInterface}" counter queue num 0 bypass
              iifname "${cfg.dmzInterface}" oifname "${cfg.lanInterface}" counter queue num 0 bypass
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
              HOME_NET = "[${
                lib.concatStringsSep "," [
                  addresses.home.network
                  addresses.infra.network
                  addresses.dmz.network
                ]
              }]";
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
