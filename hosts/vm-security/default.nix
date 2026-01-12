{
  system.stateVersion = "25.11";

  custom = {
    platform.vm = {
      hardware.enable = true;
      disks.enableMain = true;
    };

    roles = {
      workstation = {
        catppuccin.enable = true;
        packages.enable = true;
      };

      security = {
        network.enable = true;
        packages.enable = true;
        services.enable = true;
      };
    };
  };
}
