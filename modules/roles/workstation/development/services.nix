{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.workstation.development.services;
in
{
  options.custom.roles.workstation.development.services = with lib; {
    enable = mkEnableOption "Enable development services";
  };

  config = lib.mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ]; # to build aarch64 kernel for pi

    services = {
      xserver.enable = true;
      displayManager = {
        plasma-login-manager.enable = true;
        defaultSession = "niri";
      };
      desktopManager.plasma6.enable = true;
    };

    xdg.portal = {
      enable = true;
      config.common.default-portal = "kde";
      extraPortals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];
    };

    systemd.services = {
      display-manager = {
        restartIfChanged = false;
        stopIfChanged = false;
      };
    };

    security.pam.services = {
      login.kwallet.enable = true;
    };
  };
}
