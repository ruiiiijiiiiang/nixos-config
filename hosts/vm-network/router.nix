{
  config,
  consts,
  lib,
  utilFns,
  ...
}:
let
  inherit (import ../../lib/keys.nix) wg;
  inherit (consts) addresses ports;
  inherit (utilFns) mkReservations;
  wanIf = "ens18";
  lanIf = "ens19";
  wgIf = "wg0";
in
{
  age.secrets = {
    wireguard-server-private-key.file = ../../secrets/wireguard/server-private-key.age;
    wireguard-framework-preshared-key.file = ../../secrets/wireguard/framework-preshared-key.age;
    wireguard-iphone-preshared-key.file = ../../secrets/wireguard/iphone-preshared-key.age;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
  };

  networking = {
    interfaces.${wanIf}.useDHCP = true;

    interfaces.${lanIf} = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = addresses.home.hosts.vm-network;
          prefixLength = 24;
        }
      ];
    };

    nat = {
      enable = true;
      externalInterface = wanIf;
      internalInterfaces = [
        lanIf
        wgIf
      ];
    };

    firewall = {
      enable = true;
      trustedInterfaces = [
        lanIf
        wgIf
      ];

      allowedTCPPorts = lib.mkForce [ ];
      allowedUDPPorts = lib.mkForce [ ports.wireguard ];

      interfaces.${wanIf} = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ports.wireguard ];
      };
    };

    wireguard.interfaces.${wgIf} = {
      ips = [ "${addresses.vpn.hosts.vm-network}/24" ];
      listenPort = ports.wireguard;
      privateKeyFile = config.age.secrets.wireguard-server-private-key.path;

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
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ lanIf ];
      };
      valid-lifetime = 86400;
      subnet4 = [
        {
          id = 1;
          reservations = mkReservations;
          subnet = addresses.home.network;
          pools = [ { pool = "192.168.1.50 - 192.168.1.200"; } ];
          option-data = [
            {
              name = "routers";
              data = addresses.home.hosts.vm-network;
            }
            {
              name = "domain-name-servers";
              data = "${addresses.home.hosts.vm-network}, ${addresses.home.hosts.pi}, ${addresses.home.hosts.pi-legacy}";
            }
          ];
        }
      ];
    };
  };
}
