let
  hostName = "desktop";
in
{
  system.stateVersion = "26.05";
  networking.hostName = hostName;

  custom = {
    platforms.desktop = {
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
      infra.podman.enable = true;
      security.wazuh.agent.enable = true;
    };
  };
}
