{ config, lib, pkgs, ... }:
with lib;
{
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    binfmt.emulatedSystems = [ "aarch64-linux" ]; # to build aarch64 kernel for pi

    kernelPackages = pkgs.linuxPackages_latest;

    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [
      "amdgpu"
      "mt7921e"
    ];
    kernelModules = [
      "mt7921e"
    ];
    blacklistedKernelModules = [
      "kvm-amd" # "kvm-amd" conflicts with virtualbox
    ];
    extraModulePackages = [ ];

    kernelParams = [
      "quiet"
      "splash"
      "resume=UUID=e01c20a2-fff9-4685-ab9d-1c20da55f6a0"
    ];
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/7279-99D8";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    "/" = {
      device = "/dev/disk/by-uuid/e1da5afa-cc18-4576-be7d-4edb5f93d857";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress=zstd"
        "ssd"
        "subvol=@"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/e1da5afa-cc18-4576-be7d-4edb5f93d857";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress=zstd"
        "ssd"
        "subvol=@home"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/e1da5afa-cc18-4576-be7d-4edb5f93d857";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress=zstd"
        "ssd"
        "subvol=@nix"
      ];
    };

    "/tmp" = {
      device = "/dev/disk/by-uuid/e1da5afa-cc18-4576-be7d-4edb5f93d857";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress=zstd"
        "ssd"
        "subvol=@tmp"
        "nodatacow"
      ];
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/e1da5afa-cc18-4576-be7d-4edb5f93d857";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress=zstd"
        "ssd"
        "subvol=@log"
        "nodatacow"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/e01c20a2-fff9-4685-ab9d-1c20da55f6a0"; }
  ];

  zramSwap.enable = true;

  nixpkgs.hostPlatform = mkDefault "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
  };

  services.fstrim.enable = true;
  services.fwupd.enable = true;
}
