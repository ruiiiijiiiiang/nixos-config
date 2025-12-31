{ homeConfigurations, ... }: {
  imports = [
    ../../modules
    ../common
    ../common/vm
    ../common/gui
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  home-manager.users.rui = homeConfigurations.vm-security;

  system.stateVersion = "25.11";
}
