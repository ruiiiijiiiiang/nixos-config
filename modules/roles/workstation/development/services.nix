{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) username;
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
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
      desktopManager.plasma6.enable = true;
    };

    security.pam.services = {
      sddm.enableKwallet = true;
      ${username}.kwallet.enable = true;
    };

    system.autoUpgrade.enable = true;

    xdg.portal = {
      enable = true;
      config.common.default-portal = "kde";
      extraPortals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];
    };
  };
}
