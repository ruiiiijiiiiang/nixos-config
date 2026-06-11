{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.platforms.framework.networking;
in
{
  options.custom.platforms.framework.networking = with lib; {
    enable = mkEnableOption "Enable Framework networking settings";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        enable = true;
        settings = {
          connection-ethernet = {
            match-device = "type:ethernet";
            "ipv4.route-metric" = 100;
            "ipv6.route-metric" = 100;
          };
          connection-wifi = {
            match-device = "type:wifi";
            "ipv4.route-metric" = 600;
            "ipv6.route-metric" = 600;
          };
        };
      };
    };

    users.users.${username}.extraGroups = [ "networkmanager" ];
  };
}
