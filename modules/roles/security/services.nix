{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.roles.security.services;
in
{
  options.custom.roles.security.services = with lib; {
    enable = mkEnableOption "Security role services";
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
        desktopManager.lxqt.enable = true;
        videoDrivers = [ "modesetting" ];
      };

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };
  };
}
