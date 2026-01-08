{
  imports = [
    ../../modules
    ./hardware.nix
    ./nixos.nix
    ./network.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.05";

  custom = {
    desktop = {
      catppuccin.enable = true;
      flatpak.enable = true;
      packages.enable = true;
    };

    selfhost = {
      syncthing.enable = true;
      wazuh.agent.enable = true;
    };
  };
}
