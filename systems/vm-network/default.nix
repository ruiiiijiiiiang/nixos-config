{ inputs, ... }:
with inputs;
{
  imports = [
    disko.nixosModules.disko
    ../../modules
    ../common/network.nix
    ../common/nixos.nix
    ../common/services.nix
    ../common/users.nix
    ./hardware.nix
    ./network.nix
    # ./nixos.nix
    # ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.11";
}
