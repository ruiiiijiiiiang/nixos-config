{
  imports = [
    ../../modules
    ../common
    ./hardware.nix
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.05";
}
