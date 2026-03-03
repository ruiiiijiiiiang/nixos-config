{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platforms.vm.kernel;
in
{
  options.custom.platforms.vm.kernel = with lib; {
    enable = mkEnableOption "Custom kernel config for vm";
    gpuPassthrough = mkEnableOption "Allow PIC GPU passthrough";
    workstation = mkEnableOption "Enable workstation features";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      initrd = {
        availableKernelModules = [
          "virtio_pci"
          "virtio_blk"
          "virtio_net"
          "virtio_fs"
          "sd_mod"
          "sr_mod"
        ]
        ++ lib.optionals cfg.gpuPassthrough [ "amdgpu" ]
        ++ lib.optionals cfg.workstation [ "virtio_gpu" ];

        kernelModules =
          (lib.optionals cfg.gpuPassthrough [ "amdgpu" ]) ++ (lib.optionals cfg.workstation [ "virtio_gpu" ]);
      };
      kernelModules = [ "kvm-amd" ];
      kernelParams = [
        "console=tty1"
        "console=ttyS0"
      ]
      ++ lib.optionals cfg.gpuPassthrough [
        "amdgpu.cwsr_enable=0"
        "amdgpu.gpu_recovery=1"
        "iommu=pt"
        "pci=realloc"
        "kvm.ignore_msrs=1"
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
