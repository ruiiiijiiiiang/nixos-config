{
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.custom.platform.framework.hardware;
in
{
  options.custom.platform.framework.hardware = with lib; {
    enable = mkEnableOption "Framework laptop hardware config";
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = lib.mkIf cfg.enable {
    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;

      binfmt.emulatedSystems = [ "aarch64-linux" ]; # to build aarch64 kernel for pi

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
      extraModulePackages = [ ];

      kernelParams = [
        "quiet"
        "splash"
        "resume=/dev/disk/by-label/NIXSWAP"
      ];
    };

    fileSystems = {
      "/boot" = {
        device = "/dev/disk/by-label/NIXBOOT";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      "/" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@"
        ];
      };

      "/home" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@home"
        ];
      };

      "/nix" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@nix"
        ];
      };

      "/tmp" = {
        device = "/dev/disk/by-label/NIXROOT";
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
        device = "/dev/disk/by-label/NIXROOT";
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
      { device = "/dev/disk/by-label/NIXSWAP"; }
    ];

    hardware = {
      cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      bluetooth.enable = true;
    };

    services.fwupd.enable = true;
  };
}
