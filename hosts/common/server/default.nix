{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ./network.nix
    ./security.nix
    ./services.nix
  ];

  environment.variables = {
    EDITOR = mkForce "vim";
  };
}
