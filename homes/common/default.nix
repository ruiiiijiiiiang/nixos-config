{ consts, ... }:
let
  inherit (consts) username home;
  flakePath = "${home}/nixos-config";
in
{
  imports = [
    ./configs.nix
    ./files
  ];

  home = {
    inherit username;
    homeDirectory = home;
    stateVersion = "25.05";
  };

  programs = {
    home-manager.enable = true;
    nh = {
      enable = true;
      flake = flakePath;
      clean = {
        enable = true;
        dates = "weekly";
      };
    };
  };
}
