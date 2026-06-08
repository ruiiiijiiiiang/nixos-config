{
  config,
  consts,
  helpers,
  keys,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) addresses ports endpoints;
  inherit (helpers) getHostAddress;
  inherit (keys) wg;
  cfg = config.custom.services.networking.wireguard.client;

  mkWgInterface =
    {
      autostart ? true,
      allowedIPs ? cfg.allowedIPs,
    }:
    {
      inherit autostart;
      inherit (cfg) privateKeyFile;
      address = [
        "${
          getHostAddress {
            inherit (cfg) hostName;
            network = "wg";
          }
        }/32"
        "${
          getHostAddress {
            inherit (cfg) hostName;
            network = "wg";
            isV6 = true;
          }
        }/128"
      ];
      dns = [
        addresses.infra.vip.dns
        addresses.infra.vip.dns-v6
      ];
      peers = [
        {
          inherit (wg.vm-network) publicKey;
          inherit (cfg) presharedKeyFile;
          inherit allowedIPs;
          endpoint = "${endpoints.vpn-server}:${toString ports.wireguard}";
          persistentKeepalive = 25;
        }
      ];
    };

  wgServiceConfig = {
    after = [
      "network-online.target"
      "nss-lookup.target"
    ];
    wants = [ "network-online.target" ];
    unitConfig = {
      StartLimitIntervalSec = 120;
      StartLimitBurst = 5;
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
in
{
  options.custom.services.networking.wireguard.client = with lib; {
    enable = mkEnableOption "Enable WireGuard client";
    wgInterface = mkOption {
      type = types.str;
      description = "WireGuard interface name.";
      default = "wg0";
    };
    hostName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "WireGuard client host name in consts.addresses.wg.hosts.";
    };
    privateKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "WireGuard client private key path.";
    };
    presharedKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "WireGuard client preshared key path.";
    };
    allowedIPs = mkOption {
      type = types.listOf types.str;
      default = [
        addresses.infra.network
        addresses.infra.network-v6
        addresses.dmz.network
        addresses.dmz.network-v6
        addresses.wg.network
        addresses.wg.network-v6
      ];
      description = "Subnets routed through the WireGuard tunnel.";
    };
    fullTunnel = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic toggling of full-tunnel WireGuard on open Wi-Fi.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              lib.hasAttrByPath [ "wg" "hosts" cfg.hostName ] addresses
              && lib.hasAttrByPath [ "wg" "hosts" "${cfg.hostName}-v6" ] addresses;
            message = "WireGuard client hostName '${cfg.hostName}' and '${cfg.hostName}-v6' must exist in consts.addresses.wg.hosts.";
          }
          {
            assertion = cfg.privateKeyFile != null && cfg.presharedKeyFile != null;
            message = "WireGuard client requires privateKeyFile and presharedKeyFile.";
          }
          {
            assertion = cfg.wgInterface != "";
            message = "WireGuard client interface name must not be empty.";
          }
          {
            assertion = cfg.allowedIPs != [ ];
            message = "WireGuard client requires at least one allowed IP/network.";
          }
        ];
      }

      (lib.mkIf (!cfg.fullTunnel) {
        networking.wg-quick.interfaces.${cfg.wgInterface} = mkWgInterface { };

        systemd.services."wg-quick-${cfg.wgInterface}" = wgServiceConfig;
      })

      (lib.mkIf cfg.fullTunnel {
        networking.wg-quick.interfaces = {
          "${cfg.wgInterface}-split" = mkWgInterface {
            autostart = false;
          };
          "${cfg.wgInterface}-full" = mkWgInterface {
            autostart = false;
            allowedIPs = [
              "${addresses.any}/0"
              "${addresses.any-v6}/0"
            ];
          };
        };

        systemd.services."wg-quick-${cfg.wgInterface}-split" = wgServiceConfig;
        systemd.services."wg-quick-${cfg.wgInterface}-full" = wgServiceConfig;

        networking.networkmanager.dispatcherScripts = [
          {
            source = "${
              pkgs.writeShellApplication {
                name = "wg-toggle";
                runtimeInputs = [
                  pkgs.networkmanager
                  pkgs.systemd
                  pkgs.util-linux
                ];
                text = ''
                  INTERFACE="$1"
                  ACTION="$2"
                  CONNECTION_UUID="$3"

                  DEV_TYPE=$(nmcli -g GENERAL.TYPE device show "$INTERFACE" 2>/dev/null)

                  if [ "$DEV_TYPE" = "wifi" ]; then
                    if [ "$ACTION" = "up" ]; then
                      IP_METHOD=$(nmcli -g ipv4.method connection show "$CONNECTION_UUID" 2>/dev/null)
                      SEC=$(nmcli -t -f ACTIVE,SECURITY dev wifi | grep '^yes:' | cut -d: -f2)

                      if [ "$IP_METHOD" = "manual" ]; then
                        echo "Connected to Home Wi-Fi (Static IP). Stopping VPNs..." | logger -t wg-toggle
                        systemctl stop wg-quick-${cfg.wgInterface}-split.service wg-quick-${cfg.wgInterface}-full.service
                      elif [ -z "$SEC" ] || [ "$SEC" = "--" ]; then
                        echo "Connected to OPEN Wi-Fi. Activating full-tunnel VPN..." | logger -t wg-toggle
                        systemctl stop wg-quick-${cfg.wgInterface}-split.service
                        systemctl start wg-quick-${cfg.wgInterface}-full.service
                      else
                        echo "Connected to SECURE Wi-Fi. Activating split-tunnel VPN..." | logger -t wg-toggle
                        systemctl stop wg-quick-${cfg.wgInterface}-full.service
                        systemctl start wg-quick-${cfg.wgInterface}-split.service
                      fi
                    elif [ "$ACTION" = "down" ]; then
                      echo "Wi-Fi disconnected. Stopping VPNs..." | logger -t wg-toggle
                      systemctl stop wg-quick-${cfg.wgInterface}-split.service wg-quick-${cfg.wgInterface}-full.service
                    fi
                  fi
                '';
              }
            }/bin/wg-toggle";
            type = "basic";
          }
        ];
      })
    ]
  );
}
