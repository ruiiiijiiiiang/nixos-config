{ inputs, lib, ... }:
let
  consts = import ../lib/consts.nix;

  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  helpers = import ../lib/helpers.nix {
    inherit consts lib pkgs;
  };

  inherit (consts) home;

  mkHome =
    {
      homeConfig,
      dotfiles ? "local",
    }:
    let
      dotfilesRoot =
        {
          flake = inputs.dotfiles.lib.source;
          local = "${home}/dotfiles";
        }
        .${dotfiles};
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit
          consts
          helpers
          dotfilesRoot
          ;
      };
      modules = [
        ../homes/modules
        homeConfig
      ];
    };
in
{
  flake.homeConfigurations = {
    arch = mkHome {
      homeConfig = ../homes/configs/arch.nix;
      dotfiles = "local";
    };
  };
}
