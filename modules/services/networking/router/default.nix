{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts) addresses;
  inherit (helpers) getReservations;
  cfg = config.custom.services.networking.router;
in
{
  options.custom.services.networking.router = with lib; {
    enable = mkEnableOption "Network router";
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface connecting to the WAN";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface connecting to the LAN";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "Router is enabled but required interfaces are missing.";
      }
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
    };

    networking = {
      interfaces.${cfg.wanInterface}.useDHCP = true;

      interfaces.${cfg.lanInterface} = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = addresses.home.hosts.${config.networking.hostName};
            prefixLength = 24;
          }
        ];
      };

      nat = {
        enable = true;
        externalInterface = cfg.wanInterface;
        internalInterfaces = [ cfg.lanInterface ];
      };

      firewall = {
        enable = true;
        trustedInterfaces = [ cfg.lanInterface ];

        interfaces.${cfg.wanInterface} = {
          allowedTCPPorts = [ ];
          allowedUDPPorts = [ ];
        };
      };
    };

    services.kea.dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [ cfg.lanInterface ];
        };
        valid-lifetime = 86400;
        subnet4 = [
          {
            id = 1;
            reservations = getReservations;
            subnet = addresses.home.network;
            pools = [ { pool = "${addresses.home.dhcp-min} - ${addresses.home.dhcp-max}"; } ];
            option-data = [
              {
                name = "routers";
                data = addresses.home.hosts.vm-network;
              }
              {
                name = "domain-name-servers";
                data = addresses.home.vip.dns;
              }
            ];
          }
        ];
      };
    };
  };
}
