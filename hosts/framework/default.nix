{ config, ... }:

{
  imports = [
    ../../modules
    ./hardware.nix
    ./nixos.nix
    ./packages.nix
    ./services.nix
  ];

  system.stateVersion = "25.05";
  networking.hostName = "framework";

  age.secrets = {
    wireguard-framework-private-key.file = ../../secrets/wireguard/framework-private-key.age;
    wireguard-framework-preshared-key.file = ../../secrets/wireguard/framework-preshared-key.age;
  };

  custom = {
    desktop = {
      catppuccin.enable = true;
      flatpak.enable = true;
      packages.enable = true;
    };

    selfhost = {
      syncthing.enable = true;
      wazuh.agent.enable = true;

      wireguard.client = {
        enable = true;
        inherit (config.age.secrets) privateKeyFile;
        inherit (config.age.secrets) presharedKeyFile;
      };
    };
  };
}
