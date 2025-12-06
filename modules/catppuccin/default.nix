{
  config,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rui.catppuccin;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
  ];

  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      flavor = "frappe";
      accent = "lavender";
      sddm = {
        font = "Maple Mono";
        fontSize = "12";
        loginBackground = true;
        background = "/home/rui/Pictures/wallpaper.png";
      };
    };
  };
}
