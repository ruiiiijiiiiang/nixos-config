{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../../lib/keys.nix) wg;
  inherit (consts) addresses ports vpn-endpoint;
  cfg = config.custom.services.networking.wireguard.client;
in
{
  options.custom.services.networking.wireguard.client = with lib; {
    enable = mkEnableOption "WireGuard VPN client";
    wgInterface = mkOption {
      type = types.str;
      description = "Interface to use for WireGuard client";
      default = "wg0";
    };
    address = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WireGuard client address";
    };
    privateKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to WireGuard client private key";
    };
    presharedKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to WireGuard client preshared key";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.address != null;
        message = "WireGuard client is enabled but client address is missing.";
      }
      {
        assertion = cfg.privateKeyFile != null && cfg.client.presharedKeyFile != null;
        message = "WireGuard client is enabled but required keys are missing.";
      }
    ];

    networking.wg-quick.interfaces.${cfg.wgInterface} = {
      inherit (cfg) privateKeyFile;
      address = [ "${cfg.address}/32" ];
      dns = [ addresses.infra.vip.dns ];
      peers = [
        {
          inherit (wg.vm-network) publicKey;
          inherit (cfg) presharedKeyFile;
          endpoint = "${vpn-endpoint}:${toString ports.wireguard}";
          allowedIPs = [
            addresses.home.network
            addresses.infra.network
            addresses.vpn.network
          ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
