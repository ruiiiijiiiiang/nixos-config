{ ... }:

let
  username = "rui";
  homePath = "/home/${username}";
  flakePath = "${homePath}/nixos-config";
in
{
  home = {
    inherit username;
    homeDirectory = homePath;
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
