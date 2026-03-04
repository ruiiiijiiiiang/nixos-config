{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) addresses;
  cfg = config.custom.services.security.suricata;
in
{
  options.custom.services.security.suricata = with lib; {
    enable = mkEnableOption "Enable Suricata IDS/IPS";
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WAN interface name.";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN interface name.";
    };
    infraInterface = mkOption {
      type = types.str;
      default = "infra0";
      description = "Infra VLAN interface name.";
    };
    dmzInterface = mkOption {
      type = types.str;
      default = "dmz0";
      description = "DMZ VLAN interface name.";
    };
    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard interface name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "Suricata requires WAN and LAN interfaces.";
      }
    ];

    environment.systemPackages = [ pkgs.ethtool ];

    networking = {
      localCommands = /* bash */ ''
        ${pkgs.ethtool}/bin/ethtool -K ${cfg.wanInterface} gro off lro off || true
        ${pkgs.ethtool}/bin/ethtool -K ${cfg.lanInterface} gro off lro off || true
      '';

      nftables.tables = {
        "suricata-ips" = {
          family = "inet";
          content = /* bash */ ''
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
          stats.interval = "60";
          threshold-file = "${pkgs.writeText "threshold.conf" ''
            # Suppress "Packet seen on wrong thread"
            suppress gen_id 1, sig_id 2210059

            # Suppress "3way handshake wrong seq wrong ack"
            suppress gen_id 1, sig_id 2210010

            # Suppress "Ethertype unknown"
            suppress gen_id 1, sig_id 2200121
          ''}";
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
                filename = "/var/log/suricata/eve.json";
                file-mode = "0644";
                pcap-file = false;
                rotate-interval = "day";
                types = [
                  "alert"
                  "drop"
                  {
                    ssh = {
                      enabled = true;
                    };
                  }
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
    };
  };
}
