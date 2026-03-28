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
    ];

    networking.wg-quick.interfaces.${cfg.wgInterface} = {
      inherit (cfg) privateKeyFile;
      address = [ "${cfg.address}/32" ];
      dns = [ addresses.infra.vip.dns ];
      peers = [
        {
          inherit (wg.vm-network) publicKey;
          inherit (cfg) presharedKeyFile;
          endpoint = "${endpoints.vpn-server}:${toString ports.wireguard}";
          allowedIPs = [
            addresses.home.network
            addresses.infra.network
            addresses.vpn.network
          ];
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
