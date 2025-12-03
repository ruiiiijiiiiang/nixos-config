{ config, lib, inputs, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  keys = import ../../lib/keys.nix;
in with consts; with keys; {
  age.secrets = {
    wg-privatekey.file = ../../secrets/wg-privatekey.age;
    wg-presharedkey.file = ../../secrets/wg-presharedkey.age;
  };

  networking = {
    hostName = "rui-nixos";

    wg-quick.interfaces.wg-home = {
      privateKeyFile = config.age.secrets.wg-privatekey.path;
      address = [ "${addresses.vpn.hosts.nixos}/32" ];
      dns = [ addresses.home.hosts.pi.ethernet addresses.home.hosts.pi.wifi ];
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
