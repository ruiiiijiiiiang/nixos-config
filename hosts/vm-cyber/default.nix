{
  system.stateVersion = "25.11";
  networking.hostName = "vm-cyber";

  custom = {
    platforms.vm = {
      kernel = {
        enable = true;
        workstation = true;
      };

      libvirt = {
        enable = true;
        config = {
          vcpu = {
            count = 4;
          };
          memory = {
            count = 4;
          };
        };
      };

      disks.enable = true;
    };

    roles = {
      workstation = {
        # catppuccin.enable = true;
        packages.enable = true;

        cyber = {
          networking.enable = true;
          packages.enable = true;
          services.enable = true;
          security.enable = true;
        };
      };
    };
  };
}
