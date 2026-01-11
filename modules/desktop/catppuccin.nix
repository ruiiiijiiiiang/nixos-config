{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.custom.desktop.catppuccin;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
  ];

  options.custom.desktop.catppuccin = with lib; {
    enable = mkEnableOption "Custom catppuccin theme setup";
  };

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