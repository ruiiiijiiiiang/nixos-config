{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../../lib/keys.nix) wg;
  inherit (consts) addresses ports vpn-endpoint;
  cfg = config.custom.services.networking.wireguard;
in
{
  options.custom.services.networking.wireguard.client = with lib; {
    enable = mkEnableOption "WireGuard VPN client";
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

  config = lib.mkIf cfg.client.enable {
    assertions = [
      {
        assertion = cfg.client.address != null;
        message = "WireGuard client is enabled but client address is missing.";
      }
      {
        assertion = cfg.client.privateKeyFile != null && cfg.client.presharedKeyFile != null;
        message = "WireGuard client is enabled but required keys are missing.";
      }
    ];

    networking.wg-quick.interfaces.wg-home = {
      inherit (cfg.client) privateKeyFile;
      address = [ "${cfg.client.address}/32" ];
      dns = [ addresses.home.vip.dns ];
      peers = [
        {
          inherit (wg.vm-network) publicKey;
          inherit (cfg.client) presharedKeyFile;
          endpoint = "${vpn-endpoint}:${toString ports.wireguard}";
          allowedIPs = [
            addresses.home.network
            addresses.vpn.network
          ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
