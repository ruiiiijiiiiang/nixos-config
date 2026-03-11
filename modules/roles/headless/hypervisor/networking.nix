{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) domain addresses vlan-ids;
  cfg = config.custom.roles.headless.hypervisor.networking;
  vlanInterface = "${cfg.lanBridge}.${toString cfg.vlanId}";
in
{
  options.custom.roles.headless.hypervisor.networking = with lib; {
    enable = mkEnableOption "Enable hypervisor networking";
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN interface name.";
    };
    lanBridge = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN bridge name.";
    };
    vlanId = mkOption {
      type = types.ints.positive;
      default = vlan-ids.infra;
      description = "VLAN ID for infra.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      useNetworkd = true;
      useDHCP = false;

      networkmanager.unmanaged = [
        cfg.lanBridge
        cfg.lanInterface
      ];
    };

    # Using the traditional networking module is quite brittle when working with a NIC that's passed through to a guest.
    # The systemd.network module is much more robust and it has better syntax for handling vlan filtering.
    systemd.network = {
      enable = true;

      netdevs = {
        "10-${cfg.lanBridge}" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "${cfg.lanBridge}";
          };
          bridgeConfig = {
            VLANFiltering = true;
          };
        };

        "20-${vlanInterface}" = {
          netdevConfig = {
            Kind = "vlan";
            Name = vlanInterface;
          };
          vlanConfig = {
            Id = cfg.vlanId;
          };
        };
      };

      networks = {
        "10-${cfg.lanInterface}" = {
          matchConfig.Name = cfg.lanInterface;
          networkConfig = {
            Bridge = cfg.lanBridge;
            LinkLocalAddressing = "no";
          };
          bridgeVLANs = [
            {
              VLAN = vlan-ids.home;
              PVID = vlan-ids.home;
              EgressUntagged = true;
            }
            { VLAN = vlan-ids.infra; }
            { VLAN = vlan-ids.dmz; }
          ];
          linkConfig.RequiredForOnline = "enslaved";
        };

        "20-${cfg.lanBridge}" = {
          matchConfig.Name = cfg.lanBridge;
          networkConfig = {
            VLAN = [ vlanInterface ];
            LinkLocalAddressing = "no";
          };
          bridgeVLANs = [
            { VLAN = vlan-ids.infra; }
          ];
          linkConfig.RequiredForOnline = "carrier";
        };

        "30-${vlanInterface}" = {
          matchConfig.Name = vlanInterface;
          networkConfig = {
            Address = "${addresses.infra.hosts.hypervisor}/24";
            Gateway = addresses.infra.hosts.vm-network;
            DNS = [ addresses.infra.vip.dns ];
            Domains = [ domain ];
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };
    };
  };
}
