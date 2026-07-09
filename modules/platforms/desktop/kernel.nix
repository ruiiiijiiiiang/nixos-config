{
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.custom.platforms.desktop.kernel;
in
{
  options.custom.platforms.desktop.kernel = with lib; {
    enable = mkEnableOption "Enable Desktop kernel settings";
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
      ];
      initrd.kernelModules = [
        "amdgpu"
      ];

      kernelParams = [
        "quiet"
        "splash"
      ];
    };

    hardware = {
      cpu.amd.updateMicrocode = true;
      bluetooth.enable = true;
    };
  };
}
