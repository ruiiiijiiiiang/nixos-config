{ lib, inputs, ... }:

{
  imports = [
    ./network.nix
    ./nixos.nix
    ./packages.nix
    ./services.nix
    ./users.nix
    inputs.agenix.nixosModules.default
  ];

  environment.variables = {
    OS = "nixos";
    EDITOR = "nvim";
    NH_FLAKE = "/home/rui/nixos-config/";
  };

  age.identityPaths = [ "/home/rui/.ssh/id_ed25519" ];
}
