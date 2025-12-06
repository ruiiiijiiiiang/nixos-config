{ lib, pkgs, ... }:

let
  utils = import ../../../lib/utils.nix { inherit lib pkgs; };

  startSwayOSDScript = pkgs.writeShellScript "start-swayosd" ''
    #!/bin/bash

    ${utils.findBinaryFunctionString}
    SWAYOSD_PATH=$(find_binary_path "swayosd-server") || exit 1

    echo "Starting swayosd from $SWAYOSD_PATH..."
    exec "$SWAYOSD_PATH"
  '';
in
{
  systemd.user.services.swayosd-server = {
    Unit = {
      Description = "Sway Onscreen Display";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${startSwayOSDScript}";
      Restart = "on-failure";
    };
  };
}
