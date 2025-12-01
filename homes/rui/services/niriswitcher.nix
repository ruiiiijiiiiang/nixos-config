{ lib, pkgs, ... }:

let
  utils = import ../../../lib/utils.nix { inherit lib pkgs; };

  startNiriswitcherScript = pkgs.writeShellScript "start-niriswitcher" ''
    #!/bin/bash

    ${utils.findBinaryFunctionString}
    NIRISWITCHER_PATH=$(find_binary_path "niriswitcher") || exit 1

    echo "Starting niriswitcher from $NIRISWITCHER_PATH..."
    exec "$NIRISWITCHER_PATH"
  '';
in {
  systemd.user.services.niriswitcher = {
    Unit = {
      Description = "Window Switcher for Niri";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${startNiriswitcherScript}";
      Restart = "on-failure";
    };
  };
}
