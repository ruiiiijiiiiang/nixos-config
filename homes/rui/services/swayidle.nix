{ lib, pkgs, ... }:

let
  utils = import ../../../lib/utils.nix { inherit lib pkgs; };

  startSwayIdleScript = pkgs.writeShellScript "start-swayidle" ''
    #!/bin/bash

    ${utils.findBinaryFunctionString}
    SWAYIDLE_PATH=$(find_binary_path "swayidle") || exit 1

    echo "Starting swayidle from $SWAYIDLE_PATH..."
    exec "$SWAYIDLE_PATH" -w \
      timeout 600 "swaylock -f" \
      timeout 1200 "systemctl suspend" \
      before-sleep "swaylock -f"
  '';
in
{
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Sway Idle Management Daemon";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${startSwayIdleScript}";
      Restart = "on-failure";
    };
  };
}
