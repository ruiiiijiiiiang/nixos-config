{ consts, ... }:
let
  inherit (consts) username home;
in
{
  home = {
    inherit username;
    homeDirectory = home;
  };

  programs = {
    home-manager.enable = true;
  };
}
