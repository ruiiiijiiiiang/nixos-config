{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platforms.framework.networking;
in
{
  options.custom.platforms.framework.networking = with lib; {
    enable = mkEnableOption "Enable Framework networking settings";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        dispatcherScripts = [
          {
            source = "${
              pkgs.writeShellApplication {
                name = "wifi-wired-exclusive";
                runtimeInputs = with pkgs; [
                  networkmanager
                  gnugrep
                ];
                text = ''
                  INTERFACE="$1"
                  ACTION="$2"

                  if [[ "$INTERFACE" =~ ^en|^eth ]]; then
                    if [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ]; then
                      if nmcli -t -f TYPE,STATE device | grep -q '^ethernet:connected'; then
                        if [ "$(nmcli radio wifi)" = "enabled" ]; then
                          echo "Ethernet interface connected. Disabling Wi-Fi..."
                          nmcli radio wifi off
                        fi
                      else
                        if [ "$(nmcli radio wifi)" = "disabled" ]; then
                          echo "No Ethernet interface connected. Enabling Wi-Fi..."
                          nmcli radio wifi on
                        fi
                      fi
                    fi
                  fi
                '';
              }
            }/bin/wifi-wired-exclusive";
            type = "basic";
          }
        ];
      };
    };
  };
}
