{ config, lib, ... }:
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
    };

    services = {
      logrotate.enable = true;
      journald.extraConfig = ''
        SystemMaxUse=1G
        Storage=persistent
      '';

      xserver.enable = false;
      printing.enable = false;
      avahi.enable = lib.mkDefault false;
    };
  };
}
