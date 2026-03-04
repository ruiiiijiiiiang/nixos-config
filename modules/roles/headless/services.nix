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
    enable = mkEnableOption "Enable headless services role";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      variables = {
        EDITOR = "vim";
      };

      interactiveShellInit = /* bash */ ''
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
