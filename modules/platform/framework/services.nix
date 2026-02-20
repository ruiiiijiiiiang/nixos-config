{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.platform.framework.services;
in
{
  options.custom.platform.framework.services = with lib; {
    enable = mkEnableOption "Framework-specific services";
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver.enable = true;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };

        dms-greeter = {
          enable = true;
          compositor.name = "niri";
        };
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

      fprintd = {
        enable = true;
        tod = {
          enable = true;
          driver = pkgs.libfprint-2-tod1-goodix;
        };
      };

      power-profiles-daemon.enable = true;
    };

    security.pam.services = {
      sddm.enableKwallet = true;
      ${username}.kwallet.enable = true;
    };

    xdg.portal = {
      enable = true;
      config.common.default-portal = "kde";
      extraPortals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];
    };

    virtualisation.vmware.host.enable = true;
  };
}
