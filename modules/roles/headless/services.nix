{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.headless.services;
in
{
  options.custom.roles.headless.services = with lib; {
    enable = mkEnableOption "Custom services setup for servers";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      variables = {
        EDITOR = lib.mkForce "vim";
      };

      interactiveShellInit = ''
        stats() {
          systemctl status "$1" | tspin
        }

        log() {
          if [ -z "$2" ]; then
            journalctl -u "$1" -f | tspin
          else
            journalctl -u "$1" -n "$2" | tspin
          fi
        }
      '';
    };

    virtualisation = {
      oci-containers = {
        backend = "podman";
      };
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };
      };
    };

    systemd.timers.podman-auto-update = {
      wantedBy = [ "timers.target" ];
      enable = true;
    };

    systemd.tmpfiles.rules = [
      "L+ /var/run/docker.sock - - - - /run/podman/podman.sock"
    ];

    services = {
      logrotate.enable = true;
      journald.extraConfig = ''
        SystemMaxUse=1G
        Storage=persistent
      '';

      xserver.enable = false;
      avahi.enable = false;
      printing.enable = false;
    };

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.system}.default
    ];
  };
}
