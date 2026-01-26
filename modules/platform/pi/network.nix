{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.platform.pi.network;
in
{
  options.custom.platform.pi.network = with lib; {
    enable = mkEnableOption "Raspberry Pi 4 network config";
    interface = mkOption {
      type = types.str;
      default = "end0";
      description = "Ethernet interface";
    };

    vlan = {
      enable = mkEnableOption "Raspberry Pi 4 VLAN config";
      id = mkOption {
        type = types.int;
        default = 20;
        description = "VLAN tag ID";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      useDHCP = false;

      interfaces = {
        ${cfg.interface} = {
          useDHCP = !cfg.vlan.enable;
        };
        "${cfg.interface}.${toString cfg.vlan.id}" = lib.mkIf cfg.vlan.enable {
          useDHCP = true;
        };
      };

      vlans."${cfg.interface}.${toString cfg.vlan.id}" = lib.mkIf cfg.vlan.enable {
        inherit (cfg) interface;
        inherit (cfg.vlan) id;
      };
    };
  };
}
