{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) addresses ports vlan-ids;
  cfg = config.custom.roles.headless.hypervisor.networking;
in
{
  options.custom.roles.headless.hypervisor.networking = with lib; {
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
    wanBridge = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Network bridge for WAN";
    };
    lanBridge = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Network bridge for LAN";
    };
    vlanId = mkOption {
      type = types.int;
      default = vlan-ids.infra;
      description = "VLAN tag ID for infra";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.wanInterface != null
          && cfg.lanInterface != null
          && cfg.wanBridge != null
          && cfg.lanBridge != null;
        message = "Hypervisor networking is enabled but required interfaces are missing.";
      }
    ];

    networking = {
      useDHCP = false;
      localCommands = /* bash */ ''
        ${pkgs.iproute2}/bin/ip link set dev ${cfg.lanBridge} type bridge vlan_filtering 1
      '';

      interfaces = {
        "${cfg.wanInterface}".useDHCP = false;
        "${cfg.lanInterface}".useDHCP = false;

        "${cfg.wanBridge}".useDHCP = false;
        "${cfg.lanBridge}".useDHCP = false;

        "${cfg.lanBridge}.${toString cfg.vlanId}" = {
          ipv4.addresses = [
            {
              address = addresses.infra.hosts.hypervisor;
              prefixLength = 24;
            }
          ];
        };
      };

      bridges = {
        ${cfg.wanBridge} = {
          interfaces = [ cfg.wanInterface ];
        };
        ${cfg.lanBridge} = {
          interfaces = [ cfg.lanInterface ];
        };
      };

      vlans = {
        "${cfg.lanBridge}.${toString cfg.vlanId}" = {
          id = cfg.vlanId;
          interface = cfg.lanBridge;
        };
      };

      defaultGateway = {
        address = addresses.infra.hosts.vm-network;
        interface = "${cfg.lanBridge}.${toString cfg.vlanId}";
      };

      firewall = {
        interfaces."${cfg.lanInterface}".allowedTCPPorts = [
          ports.ssh
        ];
      };
    };
  };
}
