{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ./network.nix
    ./services.nix
  ];

  environment.variables = {
    EDITOR = mkForce "vim";
  };
}
