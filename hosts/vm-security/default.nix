{
  system.stateVersion = "25.11";
  networking.hostName = "vm-security";

  custom = {
    platform.vm = {
      hardware = {
        enable = true;
        workstation = true;
      };
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
        security.enable = true;
      };
    };
  };
}
