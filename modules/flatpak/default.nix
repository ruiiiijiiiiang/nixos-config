{ config, lib, inputs, ... }:
with lib;
let
  cfg = config.rui.flatpak;
in {
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  config = mkIf cfg.enable {
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
      ];
    };
  };
}
