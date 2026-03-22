{ consts, ... }:
let
  inherit (consts) username home;
  flakePath = "${home}/nixos-config";
in
{
  home = {
    inherit username;
    homeDirectory = home;
    stateVersion = "25.05";

    sessionVariables = {
      EDITOR = "nvim";
      NH_FLAKE = flakePath;
      NH_OS_FLAKE = flakePath;
    };
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
