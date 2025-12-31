{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.custom.catppuccin;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
  ];

  config = lib.mkIf cfg.enable {
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
