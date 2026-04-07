{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../../lib/keys.nix) wg;
  inherit (consts) addresses ports endpoints;
  cfg = config.custom.services.networking.wireguard.client;
in
{
  options.custom.services.networking.wireguard.client = with lib; {
    enable = mkEnableOption "Enable WireGuard client";
    wgInterface = mkOption {
      type = types.str;
      description = "WireGuard interface name.";
      default = "wg0";
    };
    address = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WireGuard client address.";
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
        addresses.dmz.network
        addresses.wg.network
      ];
      description = "Subnets routed through the WireGuard tunnel.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.address != null;
        message = "WireGuard client requires address.";
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
        assertion = cfg.address != null && !(lib.hasInfix "/" cfg.address);
        message = "WireGuard client address must be a host IP without CIDR suffix (module appends /32).";
      }
      {
        assertion = cfg.allowedIPs != [ ];
        message = "WireGuard client requires at least one allowed IP/network.";
      }
    ];

    networking.wg-quick.interfaces.${cfg.wgInterface} = {
      inherit (cfg) privateKeyFile;
      address = [ "${cfg.address}/32" ];
      dns = [ addresses.infra.vip.dns ];
      peers = [
        {
          inherit (wg.vm-network) publicKey;
          inherit (cfg) presharedKeyFile allowedIPs;
          endpoint = "${endpoints.vpn-server}:${toString ports.wireguard}";
          persistentKeepalive = 25;
        }
      ];
    };

    systemd.services."wg-quick-${cfg.wgInterface}" = {
      after = [
        "network-online.target"
        "nss-lookup.target"
      ];
      wants = [ "network-online.target" ];
    };
  };
}
