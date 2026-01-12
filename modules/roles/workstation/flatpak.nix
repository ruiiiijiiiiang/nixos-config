{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.custom.roles.workstation.flatpak;
in
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  options.custom.roles.workstation.flatpak = with lib; {
    enable = mkEnableOption "Custom flatpak service and packages";
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
      update.auto.onCalendar = "weekly";

      packages = [
        "io.github.milkshiift.GoofCord"
        "com.spotify.Client"
        "org.upscayl.Upscayl"
        "com.simplenote.Simplenote"
        "eu.betterbird.Betterbird"
      ];
    };
  };
}