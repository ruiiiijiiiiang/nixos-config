{ lib, inputs, ... }:

{
  imports = [
    ../../modules
    ../common/network.nix
    ../common/nixos.nix
    ../common/services.nix
    ../common/users.nix
    ./hardware.nix
    ./network.nix
    ./nixos.nix
    ./packages.nix
    ./services.nix
    inputs.agenix.nixosModules.default
  ];

  system.stateVersion = "25.05";
}
