{
  config,
  consts,
  lib,
  inputs,
  ...
}:
let
  cfg = config.custom.roles.workstation.catppuccin;
  inherit (consts) home;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
  ];

  options.custom.roles.workstation.catppuccin = with lib; {
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
        background = "${home}/Pictures/wallpaper.png";
      };
    };
  };
}

