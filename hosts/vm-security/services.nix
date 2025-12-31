{
  custom = {
    catppuccin.enable = true;
  };

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
}
