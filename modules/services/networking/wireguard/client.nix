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

  wgToggleScriptText = lib.replaceStrings [ "@WG_INTERFACE@" ] [ cfg.wgInterface ] (
    lib.readFile ./wg-toggle.sh
  );

  wgToggle = pkgs.writeShellApplication {
    name = "wg-toggle";
    runtimeInputs = with pkgs; [
      networkmanager
      systemd
      util-linux
    ];
    text = wgToggleScriptText;
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
  };

  config = lib.mkIf cfg.enable {
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

    environment.systemPackages = [ wgToggle ];

    networking.networkmanager.dispatcherScripts = [
      {
        source = "${wgToggle}/bin/wg-toggle";
        type = "basic";
      }
    ];
  };
}
