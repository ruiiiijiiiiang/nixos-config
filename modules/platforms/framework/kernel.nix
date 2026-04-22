{
  config,
  lib,
  modulesPath,
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
    assertions = [
      {
        assertion =
          let
            hasResumeParam = lib.any (
              param: lib.hasPrefix "resume=/dev/disk/by-label/NIXSWAP" param
            ) config.boot.kernelParams;
            hasSwapDevice = lib.any (
              swap: (swap ? device) && swap.device == "/dev/disk/by-label/NIXSWAP"
            ) config.swapDevices;
          in
          (!hasResumeParam) || hasSwapDevice;
        message = "resume=/dev/disk/by-label/NIXSWAP requires a matching swapDevices entry.";
      }
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;

      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "sd_mod"
      ];
      initrd.kernelModules = [
        "amdgpu"
      ];

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
  };
}
