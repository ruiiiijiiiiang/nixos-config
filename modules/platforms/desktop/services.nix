{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.platforms.desktop.services;
in
{
  options.custom.platforms.desktop.services = with lib; {
    enable = mkEnableOption "Enable Desktop services";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
    };

    users.users.${username}.extraGroups = [ "networkmanager" ];

    services = {
      fwupd.enable = true;

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
  };
}
