{
  imports = [
    ../../modules
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.11";

  custom = {
    vm = {
      hardware.enable = true;
      disks.enableMain = true;
    };

    desktop = {
      catppuccin.enable = true;
      packages.enable = true;
    };
  };
}
