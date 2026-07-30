{ config, lib, ... }:
let
  cfg = config.custom.platforms.desktop.hardware;
in
{
  options.custom.platforms.desktop.hardware = with lib; {
    enable = mkEnableOption "Enable Desktop hardware settings";
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
        "ahci"
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
      bluetooth.enable = true;
    };
  };
}
