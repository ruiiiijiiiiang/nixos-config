{ ... }:

{
  imports = [
    ../../modules
    ../common/server
    ../common/vm
    ../common/hardware.nix
    ../common/network.nix
    ../common/nixos.nix
    ../common/services.nix
    ../common/users.nix
    ./network.nix
    ./services.nix
  ];

  system.stateVersion = "25.11";
}
