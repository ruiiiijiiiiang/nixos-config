{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  inherit (import ../../../lib/consts.nix) addresses;
  cfg = config.custom.selfhost.suricata;
in
{
  config = mkIf cfg.enable {
    services.suricata = {
      enable = true;
      action = "ids";
      interfaces = cfg.interfaces;
      settings = {
        HOME_NET = "[${addresses.home.network}, ${addresses.vpn.network}]";
        default-rule-path = "${pkgs.suricata}/share/suricata/rules";
        rule-files = [ "suricata.rules" ];
        outputs = [
          {
            fast = {
              enabled = "yes";
              filename = "fast.log";
              append = "yes";
            };
          }
          {
            eve-log = {
              enabled = "yes";
              filetype = "regular";
              filename = "eve.json";
              types = [
                "alert"
                "anomaly"
                "http"
                "dns"
                "tls"
              ];
            };
          }
        ];
      };
    };
  };
}
