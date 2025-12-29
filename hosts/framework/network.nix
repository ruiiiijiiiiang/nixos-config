{
  config,
  consts,
  lib,
  ...
}:
with lib;
let
  keys = import ../../lib/keys.nix;
in
with consts;
with keys;
{
  age.secrets = {
    wg-privatekey.file = ../../secrets/wg-privatekey.age;
    wg-presharedkey.file = ../../secrets/wg-presharedkey.age;
  };

  networking = {
    hostName = "framework";

    wg-quick.interfaces.wg-home = {
      privateKeyFile = config.age.secrets.wg-privatekey.path;
      address = [ "${addresses.vpn.hosts.framework}/32" ];
      dns = [
        addresses.home.hosts.vm-network
        addresses.home.hosts.pi
        addresses.home.hosts.pi-legacy
      ];
      peers = [
        {
          inherit (wg.wg-home) publicKey;
          presharedKeyFile = config.age.secrets.wg-presharedkey.path;
          endpoint = "${domains.tplink}:${toString ports.wireguard}";
          allowedIPs = [ addresses.home.network ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
