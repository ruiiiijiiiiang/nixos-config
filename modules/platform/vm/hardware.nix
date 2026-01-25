{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platform.vm.hardware;
in
{
  options.custom.platform.vm.hardware = with lib; {
    enable = mkEnableOption "Custom hardware config for vm";
    gpuPassthrough = mkEnableOption "Allow PIC GPU passthrough";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      tmp.useTmpfs = true;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      initrd = {
        availableKernelModules = [
          "ata_piix"
          "uhci_hcd"
          "virtio_pci"
          "virtio_scsi"
          "sd_mod"
          "sr_mod"
        ];

        kernelModules = lib.mkIf cfg.gpuPassthrough [ "amdgpu" ];
      };
      kernelModules = [ "kvm-amd" ];
      kernelParams = [
        "rootdelay=5"
        "console=tty1"
        "console=ttyS0"
      ];
    };

    services = {
      qemuGuest.enable = true;
      xserver.videoDrivers = lib.mkIf cfg.gpuPassthrough [ "amdgpu" ];
    };

    hardware = lib.mkIf cfg.gpuPassthrough {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          libva-utils
          rocmPackages.clr.icd
        ];
      };
    };
  };
}
