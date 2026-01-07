{ config, consts, ... }:
let
  inherit (import ../../lib/keys.nix) wg;
  inherit (consts) addresses domains ports;
in
{
  age.secrets = {
    wireguard-private-key.file = ../../secrets/wireguard/private-key.age;
    wireguard-preshared-key.file = ../../secrets/wireguard/preshared-key.age;
  };

  networking = {
    hostName = "framework";

    wg-quick.interfaces.wg-home = {
      privateKeyFile = config.age.secrets.wireguard-private-key.path;
      address = [ "${addresses.vpn.hosts.framework}/32" ];
      dns = [
        addresses.home.hosts.vm-network
        addresses.home.hosts.pi
        addresses.home.hosts.pi-legacy
      ];
      peers = [
        {
          inherit (wg.wg-home) publicKey;
          presharedKeyFile = config.age.secrets.wireguard-preshared-key.path;
          endpoint = "${domains.tplink}:${toString ports.wireguard}";
          allowedIPs = [ addresses.home.network ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
