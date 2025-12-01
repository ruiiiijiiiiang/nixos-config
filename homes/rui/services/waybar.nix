{ lib, pkgs, ... }:

let
  utils = import ../../../lib/utils.nix { inherit lib pkgs; };

  startWaybarScript = pkgs.writeShellScript "start-warbar" ''
    #!/bin/bash

    ${utils.findBinaryFunctionString}
    WAYBAR_PATH=$(find_binary_path "waybar") || exit 1

    CONFIG_FILE="$HOME/.config/waybar/config.jsonc"
    if [[ $OS == "arch" ]]; then
      CONFIG_FILE="$HOME/.config/waybar/config-arch.jsonc"
    elif [[ $OS == "nixos" ]]; then
      CONFIG_FILE="$HOME/.config/waybar/config-nixos.jsonc"
    fi

    echo "Starting waybar from $WAYBAR_PATH using config file $CONFIG_FILE..."
    exec "$WAYBAR_PATH" -c "$CONFIG_FILE"
  '';
in {
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${startWaybarScript}";
      Restart = "on-failure";
      TimeoutStopSec = 5;
    };
  };
}
