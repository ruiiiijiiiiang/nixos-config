{ inputs, ... }:
{
  imports = [
    inputs.nixos-vm-provisioner.nixosModules.guest-base
  ];

  system.stateVersion = "25.11";
  networking.hostName = "vm-cyber";

  nixos-vm-provisioner.guest.enable = true;

  custom = {
    platforms.vm = {
      kernel = {
        enable = true;
        workstation = true;
      };
      disks.enable = true;
      networking = {
        enable = true;
        lanInterface = "lan0";
      };
    };

    roles = {
      headless.packages.enable = true;
      workstation = {
        catppuccin.enable = true;
        packages.enable = true;
        cyber = {
          networking.enable = true;
          packages.enable = true;
          security.enable = true;
          services.enable = true;
        };
      };
    };
  };
}
