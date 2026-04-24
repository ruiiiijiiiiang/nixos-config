{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.platforms.framework.services;
in
{
  options.custom.platforms.framework.services = with lib; {
    enable = mkEnableOption "Enable Framework services";
  };

  config = lib.mkIf cfg.enable {
    services = {
      fwupd.enable = true;

      fprintd.enable = true;

      power-profiles-daemon.enable = true;
      upower.enable = true;

      blueman.enable = true;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };

    security.pam.services = {
      login.fprintAuth = true;
      sddm.fprintAuth = true;
      kdewallet.fprintAuth = true;
    };
  };
}
