{
  config,
  consts,
  helpers,
  keys,
  lib,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (consts) username addresses domain;
  inherit (helpers) getHostAddress getGatewayAddress;
  inherit (keys) ssh;
  cfg = config.custom.platforms.vm.networking;
in
{
  options.custom.platforms.vm.networking = with lib; {
    enable = mkEnableOption "Enable VM networking config";
    lanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LAN interface name.";
    };
    wanInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WAN interface name.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      usePredictableInterfaceNames = false;
      useNetworkd = true;
      useDHCP = false;
      networkmanager.enable = false;
    };

    systemd.network = {
      enable = true;

      links = {
        "10-lan" = lib.mkIf (cfg.lanInterface != null) {
          matchConfig = {
            Driver = "virtio_net";
            Type = "ether";
          };
          linkConfig.Name = cfg.lanInterface;
        };

        "11-wan" = lib.mkIf (cfg.wanInterface != null) {
          matchConfig = {
            Driver = "!virtio_net";
            Type = "ether";
          };
          linkConfig.Name = cfg.wanInterface;
        };
      };

      networks = lib.mkIf (cfg.lanInterface != null && cfg.wanInterface == null) {
        "10-${cfg.lanInterface}" = {
          matchConfig.Name = cfg.lanInterface;
          networkConfig = {
            Address = [
              "${getHostAddress hostName}/24"
              "${
                getHostAddress {
                  inherit hostName;
                  isV6 = true;
                }
              }/64"
            ];
            Gateway = [
              (getGatewayAddress hostName)
              (getGatewayAddress {
                inherit hostName;
                isV6 = true;
              })
            ];
            DNS = [
              addresses.infra.vip.dns
              addresses.infra.vip.dns-v6
            ];
            Domains = [ domain ];
            IPv4ReversePathFilter = "loose";
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };
    };

    users.users.${username}.openssh.authorizedKeys.keys = ssh.hypervisor;
    users.users.root.openssh.authorizedKeys.keys = ssh.hypervisor;
  };
}
