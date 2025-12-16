{ ... }:

{
  imports = [
    ../../modules
    ../common/server
    ../common/hardware.nix
    ../common/network.nix
    ../common/nixos.nix
    ../common/services.nix
    ../common/users.nix
    ./hardware.nix
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.05";
}
