{ lib, ... }:
with lib;
{
  imports = [
    ./network.nix
    ./services.nix
  ];

  environment.variables = {
    EDITOR = mkForce "vim";
  };
}
