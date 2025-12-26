{
  custom = {
    catppuccin.enable = true;
    devops.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.lxqt.enable = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    openssh.enable = true;
  };
}
