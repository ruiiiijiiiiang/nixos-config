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
    workstation = mkEnableOption "Enable workstation features";
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
        ]
        ++ lib.optionals cfg.gpuPassthrough [ "amdgpu" ]
        ++ lib.optionals cfg.workstation [ "virtio_gpu" ];

        kernelModules =
          (lib.optionals cfg.gpuPassthrough [ "amdgpu" ]) ++ (lib.optionals cfg.workstation [ "virtio-gpu" ]);
      };
      kernelModules = [ "kvm-amd" ];
      kernelParams = [
        "rootdelay=5"
        "console=tty1"
        "console=ttyS0"
      ]
      ++ lib.optionals cfg.gpuPassthrough [
        "amdgpu.cwsr_enable=0"
        "amdgpu.gpu_recovery=1"
        "iommu=pt"
        "pci=realloc"
      ];
    };

    services = {
      qemuGuest.enable = true;
      xserver.videoDrivers = lib.mkIf cfg.gpuPassthrough [ "amdgpu" ];
    };

    hardware = lib.mkIf cfg.gpuPassthrough {
      enableRedistributableFirmware = true;
      amdgpu.initrd.enable = true;
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          libva-utils
          rocmPackages.clr.icd
        ];
      };
    };
  };
}
