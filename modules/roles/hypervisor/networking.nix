{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports;
  cfg = config.custom.roles.hypervisor.networking;
in
{
  options.custom.roles.hypervisor.networking = with lib; {
    enable = mkEnableOption "Hypervisor networking config";
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for WAN";
    };
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface for LAN";
    };
    infraVlanId = mkOption {
      type = types.int;
      default = 20;
      description = "VLAN tag ID for infra";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != null && cfg.lanInterface != null;
        message = "Hypervisor networking is enabled but required interfaces are missing.";
      }
    ];

    networking = {
      useDHCP = false;

      interfaces = {
        "${cfg.wanInterface}".useDHCP = false;
        "${cfg.lanInterface}".useDHCP = false;

        "vmbr0".useDHCP = false;
        "vmbr1".useDHCP = false;

        "vmbr1.${toString cfg.infraVlanId}" = {
          ipv4.addresses = [
            {
              address = addresses.infra.hosts.hypervisor;
              prefixLength = 24;
            }
          ];
        };
      };

      bridges = {
        "vmbr0" = {
          interfaces = [ cfg.wanInterface ];
        };
        "vmbr1" = {
          interfaces = [ cfg.lanInterface ];
        };
      };

      vlans = {
        "vmbr1.${toString cfg.infraVlanId}" = {
          id = cfg.infraVlanId;
          interface = "vmbr1";
        };
      };

      defaultGateway = {
        address = addresses.infra.hosts.vm-network;
        interface = "vmbr1.${toString cfg.infraVlanId}";
      };

      firewall = {
        interfaces."${cfg.lanInterface}".allowedTCPPorts = [
          ports.ssh
        ];
      };
    };
  };
}
