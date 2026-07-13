{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.platforms.vm.hardware;
in
{
  imports = [
    inputs.nixos-vm-provisioner.nixosModules.guest-base
  ];

  options.custom.platforms.vm.hardware = with lib; {
    enable = mkEnableOption "Enable VM hardware settings";
    gpuPassthrough = mkEnableOption "Enable GPU passthrough configuration";
    workstation = mkEnableOption "Enable workstation features";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      initrd = {
        availableKernelModules = lib.optionals cfg.workstation [ "virtio_gpu" ];
        kernelModules = lib.optionals cfg.workstation [ "virtio_gpu" ];
      };

      kernelParams = lib.optionals cfg.gpuPassthrough [
        "amdgpu.cwsr_enable=0"
        "amdgpu.gpu_recovery=1"
      ];
    };

    services = {
      xserver.videoDrivers =
        lib.optionals cfg.gpuPassthrough [ "amdgpu" ] ++ lib.optionals cfg.workstation [ "modesetting" ];
      spice-vdagentd = {
        enable = lib.mkIf cfg.workstation true;
      };
    };

    hardware = lib.mkIf cfg.gpuPassthrough {
      amdgpu = {
        initrd.enable = true;
        opencl.enable = true;
      };
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}
