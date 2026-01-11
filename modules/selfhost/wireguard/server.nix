{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) wg;
  inherit (consts) addresses ports;
  cfg = config.custom.selfhost.wireguard;
in
{
  config = lib.mkIf cfg.server.enable {
    assertions = [
      {
        assertion = cfg.server.privateKeyFile != null;
        message = "WireGuard server is enabled but required key is missing.";
      }
    ];

    age.secrets = {
      wireguard-framework-preshared-key.file = ../../../secrets/wireguard/framework-preshared-key.age;
      wireguard-iphone-preshared-key.file = ../../../secrets/wireguard/iphone-preshared-key.age;
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
            inherit (wg.iphone) publicKey;
            presharedKeyFile = config.age.secrets.wireguard-iphone-preshared-key.path;
            allowedIPs = [ "${addresses.vpn.hosts.iphone}/32" ];
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
