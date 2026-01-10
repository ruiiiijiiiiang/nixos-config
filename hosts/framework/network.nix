{ config, consts, ... }:
let
  inherit (import ../../lib/keys.nix) wg;
  inherit (consts) addresses domains ports;
in
{
  age.secrets = {
    wireguard-framework-private-key.file = ../../secrets/wireguard/framework-private-key.age;
    wireguard-framework-preshared-key.file = ../../secrets/wireguard/framework-preshared-key.age;
  };

  networking = {
    hostName = "framework";

    wg-quick.interfaces.wg-home = {
      privateKeyFile = config.age.secrets.wireguard-framework-private-key.path;
      address = [ "${addresses.vpn.hosts.framework}/32" ];
      dns = [
        addresses.home.hosts.vm-network
        addresses.home.hosts.pi
        addresses.home.hosts.pi-legacy
      ];
      peers = [
        {
          inherit (wg.vm-network) publicKey;
          presharedKeyFile = config.age.secrets.wireguard-framework-preshared-key.path;
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
