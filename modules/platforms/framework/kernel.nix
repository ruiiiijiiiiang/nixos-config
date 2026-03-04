{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  cfg = config.custom.platforms.framework.kernel;
in
{
  options.custom.platforms.framework.kernel = with lib; {
    enable = mkEnableOption "Enable Framework kernel settings";
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

    hardware = {
      cpu.amd.updateMicrocode = true;
      bluetooth.enable = true;
    };

    services = {
      fwupd.enable = true;

      fprintd = {
        enable = true;
        tod = {
          enable = true;
          driver = pkgs.libfprint-2-tod1-goodix;
        };
      };

      power-profiles-daemon.enable = true;

      blueman.enable = true;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };
  };
}
