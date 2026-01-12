{ config, ... }:

{
  system.stateVersion = "25.05";
  networking.hostName = "framework";

  age.secrets = {
    wireguard-framework-private-key.file = ../../secrets/wireguard/framework-private-key.age;
    wireguard-framework-preshared-key.file = ../../secrets/wireguard/framework-preshared-key.age;
  };

  custom = {
    platform.framework = {
      hardware.enable = true;
      nixos.enable = true;
      packages.enable = true;
      services.enable = true;
    };

    roles.workstation = {
      catppuccin.enable = true;
      flatpak.enable = true;
      packages.enable = true;
    };

    services = {
      apps.tools.syncthing.enable = true;
      observability.wazuh.agent.enable = true;

      networking.wireguard.client = {
        enable = true;
        privateKeyFile = config.age.secrets.wireguard-framework-private-key.path;
        presharedKeyFile = config.age.secrets.wireguard-framework-preshared-key.path;
      };
    };
  };
}
