{ config, lib, ... }:
let
  cfg = config.custom.platforms.minipc.kernel;
in
{
  options.custom.platforms.minipc.kernel = with lib; {
    enable = mkEnableOption "Enable MiniPC kernel settings";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "sd_mod"
      ];
      kernelParams = [
        "quiet"
        "splash"
        "amd_pstate=active"
      ];
    };

    hardware = {
      cpu.amd.updateMicrocode = true;
      amdgpu.initrd.enable = true;
    };
  };
}
