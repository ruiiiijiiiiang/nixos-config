{ config, ... }:
let
  hostName = "framework";
  wgInterface = "wg0";
in
{
  system.stateVersion = "25.05";
  networking.hostName = hostName;

  age.secrets = {
    wireguard-framework-private-key.file = ../secrets/wireguard/framework-private-key.age;
    wireguard-framework-preshared-key.file = ../secrets/wireguard/framework-preshared-key.age;
  };

  custom = {
    platforms.laptop = {
      disks.enable = true;
      kernel.enable = true;
      services.enable = true;
    };

    roles = {
      headless.packages.enable = true;
      workstation = {
        catppuccin.enable = true;
        packages.enable = true;
        development = {
          flatpak.enable = true;
          nixos.enable = true;
          packages.enable = true;
          services.enable = true;
        };
      };
    };

    services = {
      apps.tools.syncthing.enable = true;

      infra = {
        podman.enable = true;
        smartd = {
          enable = true;
          workstation = true;
        };
      };

      networking.wireguard.client = {
        enable = true;
        inherit hostName wgInterface;
        privateKeyFile = config.age.secrets.wireguard-framework-private-key.path;
        presharedKeyFile = config.age.secrets.wireguard-framework-preshared-key.path;
      };

      observability.prometheus.exporters = {
        smartctl.enable = true;
      };

      security.wazuh.agent.enable = true;
    };
  };
}
