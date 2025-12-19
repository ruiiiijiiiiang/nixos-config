{ lib, ... }:
with lib;
{
  imports = [
    ./selfhost
    ./catppuccin
    ./devops
    ./flatpak
  ];

  options.custom = {
    catppuccin = {
      enable = mkEnableOption "custom catppuccin theme setup";
    };
    flatpak = {
      enable = mkEnableOption "enable flatpak service and packages";
    };
    devops = {
      enable = mkEnableOption "enable devops tools";
    };
  };
}
