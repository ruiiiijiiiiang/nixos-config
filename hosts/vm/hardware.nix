{
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };

    initrd.availableKernelModules = [
      "ahci"
      "ata_piix"
      "mptspi"
      "uhci_hcd"
      "ehci_pci"
      "sd_mod"
      "sr_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };

  swapDevices = [ ];

  # Flip as needed
  virtualisation = {
    vmware.guest.enable = false;
    virtualbox.guest.enable = false;
    hyperVGuest.enable = false;
  };
}
