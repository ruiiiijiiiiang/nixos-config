{ consts, ... }:
let
  inherit (consts) home;
in
{
  imports = [
    ./hardware.nix
    ./network.nix
    ./nixos.nix
    ./packages.nix
    ./services.nix
    ./users.nix
  ];

  environment.variables = {
    OS = "nixos";
    EDITOR = "nvim";
    NH_FLAKE = "${home}/nixos-config/";
  };
}
