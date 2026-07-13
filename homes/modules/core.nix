{ consts, inputs, ... }:
let
  inherit (consts) username home;
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  home = {
    inherit username;
    homeDirectory = home;
  };

  programs = {
    home-manager.enable = true;
  };
}
