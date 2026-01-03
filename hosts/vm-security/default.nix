{
  imports = [
    ../../modules
    ../common
    ../common/vm
    ../common/gui
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.11";
}
