{ config, lib, ... }:
let
  cfg = config.custom.platforms.minipc.hardware;
in
{
  options.custom.platforms.minipc.hardware = with lib; {
    enable = mkEnableOption "Enable MiniPC hardware settings";
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

    services.chrony = {
      enableRTCTrimming = false;
      extraConfig = ''
        rtcsync
      '';
    };
  };
}
