{ inputs, lib, ... }:
let
  consts = import ../lib/consts.nix;

  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  helpers = import ../lib/helpers.nix {
    inherit consts lib pkgs;
  };

  inherit (consts) home;
in
{
  flake.homeConfigurations = {
    arch = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit consts inputs helpers;
        dotfilesRoot = "${home}/dotfiles";
        dotfilesOutOfStore = true;
      };
      modules = [
        ../homes/modules
        ../homes/configs/arch.nix
      ];
    };
  };
}
