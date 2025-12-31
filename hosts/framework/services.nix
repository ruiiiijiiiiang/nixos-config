{ pkgs, ... }:

{
  selfhost = {
    syncthing.enable = true;
  };

  custom = {
    catppuccin.enable = true;
    flatpak.enable = true;
  };

  services = {
    power-profiles-daemon.enable = true;

    xserver.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
    };
    desktopManager.plasma6.enable = true;

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
    sddm.enableKwallet = true;
    rui.kwallet.enable = true;
  };

  xdg.portal = {
    enable = true;
    config.common.default-portal = "kde";
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  virtualisation.vmware.host.enable = true;

  selfhost.wazuh.agent.enable = true;
}
