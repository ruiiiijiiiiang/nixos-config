{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) ssh;
  inherit (consts) username addresses domain;
  inherit (helpers) getHostAddress;
  cfg = config.custom.platforms.vm.networking;
  hostName = config.networking.hostName;
  hostIp = getHostAddress hostName;
  gateway = "${addresses.home-prefix}.${lib.elemAt (lib.splitString "." hostIp) 2}.1";
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
              "${getHostAddress "${hostName}-v6"}/64"
            ];
            Gateway = gateway;
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
