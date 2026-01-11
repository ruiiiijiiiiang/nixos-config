{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) wg;
  inherit (consts) addresses domains ports;
  cfg = config.custom.selfhost.wireguard;
in
{
  options.custom.selfhost.wireguard.client = with lib; {
    enable = mkEnableOption "WireGuard VPN client";
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
        assertion = cfg.client.privateKeyFile != null && cfg.client.presharedKeyFile != null;
        message = "WireGuard client is enabled but required keys are missing.";
      }
    ];

    networking.wg-quick.interfaces.wg-home = {
      inherit (cfg.client) privateKeyFile;
      address = [ "${addresses.vpn.hosts.framework}/32" ];
      dns = [
        addresses.home.hosts.vm-network
        addresses.home.hosts.pi
        addresses.home.hosts.pi-legacy
      ];
      peers = [
        {
          inherit (wg.vm-network) publicKey;
          inherit (cfg.client) presharedKeyFile;
          endpoint = "vpn.${domains.home}:${toString ports.wireguard}";
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
