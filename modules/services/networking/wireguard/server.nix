{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../../lib/keys.nix) wg;
  inherit (consts) addresses ports;
  cfg = config.custom.services.networking.wireguard;
in
{
  options.custom.services.networking.wireguard.server = with lib; {
    enable = mkEnableOption "WireGuard VPN server";
    privateKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to WireGuard server private key";
    };
    interface = mkOption {
      type = types.str;
      description = "Interface to use for WireGuard server";
      default = "wg0";
    };
  };

  config = lib.mkIf cfg.server.enable {
    assertions = [
      {
        assertion = cfg.server.privateKeyFile != null;
        message = "WireGuard server is enabled but required key is missing.";
      }
    ];

    age.secrets = {
      wireguard-framework-preshared-key.file = ../../../../secrets/wireguard/framework-preshared-key.age;
      wireguard-iphone-16-preshared-key.file = ../../../../secrets/wireguard/iphone-16-preshared-key.age;
      wireguard-iphone-17-preshared-key.file = ../../../../secrets/wireguard/iphone-17-preshared-key.age;
    };

    networking = {
      wireguard.interfaces.${cfg.server.interface} = {
        ips = [ addresses.vpn.network ];
        listenPort = ports.wireguard;
        inherit (cfg.server) privateKeyFile;

        peers = [
          {
            inherit (wg.framework) publicKey;
            presharedKeyFile = config.age.secrets.wireguard-framework-preshared-key.path;
            allowedIPs = [ "${addresses.vpn.hosts.framework}/32" ];
          }
          {
            inherit (wg.iphone-16) publicKey;
            presharedKeyFile = config.age.secrets.wireguard-iphone-16-preshared-key.path;
            allowedIPs = [ "${addresses.vpn.hosts.iphone-16}/32" ];
          }
          {
            inherit (wg.iphone-17) publicKey;
            presharedKeyFile = config.age.secrets.wireguard-iphone-17-preshared-key.path;
            allowedIPs = [ "${addresses.vpn.hosts.iphone-17}/32" ];
          }
        ];
      };

      nat = {
        internalInterfaces = [ cfg.server.interface ];
      };

      firewall = {
        trustedInterfaces = [ cfg.server.interface ];
        allowedUDPPorts = [ ports.wireguard ];
      };
    };
  };
}
