{ lib, pkgs, ... }:

let
  utils = import ../../../lib/utils.nix { inherit lib pkgs; };

  startSwayncScript = pkgs.writeShellScript "start-swaync" ''
    #!/bin/bash

    ${utils.findBinaryFunctionString}
    SWAYNC_PATH=$(find_binary_path "swaync") || exit 1

    echo "Starting swaync from $SWAYNC_PATH..."
    exec "$SWAYNC_PATH"
  '';
in
{
  systemd.user.services.swaync = {
    Unit = {
      Description = "Sway Notification Center";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${startSwayncScript}";
      Restart = "on-failure";
    };
  };
}
