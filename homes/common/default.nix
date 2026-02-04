{ consts, ... }:
let
  inherit (consts) username home;
  flakePath = "${home}/nixos-config";
in
{
  imports = [
    ./configs.nix
  ];

  home = {
    inherit username;
    homeDirectory = home;
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
  programs.nh = {
    enable = true;
    flake = flakePath;
    clean = {
      enable = true;
      dates = "weekly";
    };
  };
}
