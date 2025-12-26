{
  imports = [
    ../../modules
    ../common
    ../common/server
    ../common/vm
    ./network.nix
    ./services.nix
  ];

  system.stateVersion = "25.11";
}
