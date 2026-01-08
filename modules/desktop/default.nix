{ lib, ... }:

{
  imports = [
    ./catppuccin.nix
    ./flatpak.nix
    ./packages.nix
  ];

  options.custom.desktop = with lib; {
    catppuccin = {
      enable = mkEnableOption "Custom catppuccin theme setup";
    };
    flatpak = {
      enable = mkEnableOption "Custom flatpak service and packages";
    };
    packages = {
      enable = mkEnableOption "Custom gui packages";
    };
  };
}
