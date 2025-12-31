{
  imports = [
    ../../modules
    ../common
    ../common/gui
    ./hardware.nix
    ./nixos.nix
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.05";
}
