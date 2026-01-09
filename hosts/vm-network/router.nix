{
  consts,
  lib,
  utilFns,
  ...
}:
let
  inherit (consts) addresses;
  inherit (utilFns) mkReservations;
  wanIf = "ens18";
  lanIf = "ens19";
in
{
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
      internalInterfaces = [ lanIf ];
    };

    firewall = {
      enable = true;
      trustedInterfaces = [ lanIf ];

      allowedTCPPorts = lib.mkForce [ ];
      allowedUDPPorts = lib.mkForce [ ];

      interfaces.${wanIf} = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };
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
