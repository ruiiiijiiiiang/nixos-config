{ ... }:

{
  imports = [
    ../../modules
    ../common
    ./hardware.nix
    ./nixos.nix
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.05";
}
