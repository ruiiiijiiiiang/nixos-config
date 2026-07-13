{ config, lib, ... }:
let
  cfg = config.custom.platforms.laptop.kernel;
in
{
  options.custom.platforms.laptop.kernel = with lib; {
    enable = mkEnableOption "Enable laptop kernel settings";
  };

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
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "sd_mod"
      ];
      blacklistedKernelModules = [
        "ucsi_acpi"
      ];

      kernelParams = [
        "quiet"
        "splash"
        "resume=/dev/disk/by-label/NIXSWAP"
        "amdgpu.abmlevel=1"
        "amd_pstate=active"
      ];
    };

    hardware = {
      cpu.amd.updateMicrocode = true;
      amdgpu.initrd.enable = true;
      bluetooth.enable = true;
    };
  };
}
