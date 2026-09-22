{
  config,
  consts,
  inputs,
  lib,
  ...
}:
let
  inherit (consts) task-schedules;
  cfg = config.custom.roles.workstation.development.flatpak;
in
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  options.custom.roles.workstation.development.flatpak = with lib; {
    enable = mkEnableOption "Enable Flatpak for development";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      remotes = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      update.auto.enable = true;
      update.auto.onCalendar = task-schedules.workstation.flatpak-update;

      packages = [
        "com.spotify.Client"
      ];
    };
  };
}
