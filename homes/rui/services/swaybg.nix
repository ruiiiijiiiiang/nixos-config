{ lib, pkgs, ... }:

let
  utils = import ../../../lib/utils.nix { inherit lib pkgs; };

  startSwayBgScript = pkgs.writeShellScript "start-swaybg" ''
    #!/bin/bash

    ${utils.findBinaryFunctionString}
    SWAYBG_PATH=$(find_binary_path "swaybg") || exit 1

    echo "Starting swaybg from $SWAYBG_PATH..."
    exec "$SWAYBG_PATH" -i /home/rui/Pictures/wallpaper.png -m fill
  '';
in
{
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Sway Wallpaper Utility";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${startSwayBgScript}";
      Restart = "on-failure";
    };
  };
}
