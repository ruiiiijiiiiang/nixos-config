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
    enable = mkEnableOption "Enable VM kernel settings";
    hardwarePassthrough = mkOption {
      type = types.nullOr (
        types.enum [
          "gpu"
          "nic"
        ]
      );
      default = null;
      description = "Enable hardware passthrough from host";
    };
    workstation = mkEnableOption "Enable workstation features";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot.enable = true;
      };
      growPartition = true;

      initrd = {
        availableKernelModules = [
          "virtio_pci"
          "virtio_blk"
          "virtio_net"
          "virtio_fs"
          "sd_mod"
          "sr_mod"
        ]
        ++ lib.optionals (cfg.hardwarePassthrough == "gpu") [ "amdgpu" ]
        ++ lib.optionals cfg.workstation [ "virtio_gpu" ];

        kernelModules =
          (lib.optionals (cfg.hardwarePassthrough == "gpu") [ "amdgpu" ])
          ++ (lib.optionals cfg.workstation [ "virtio_gpu" ]);
      };
      kernelParams = [
        "console=tty1"
        "console=ttyS0"
      ]
      ++ lib.optionals (cfg.hardwarePassthrough == "gpu") [
        "amdgpu.cwsr_enable=0"
        "amdgpu.gpu_recovery=1"
      ];
    };

    fileSystems."/".autoResize = true;

    services = {
      qemuGuest.enable = true;
      xserver.videoDrivers = lib.mkIf (cfg.hardwarePassthrough == "gpu") [ "amdgpu" ];
    };

    hardware = lib.mkIf (cfg.hardwarePassthrough == "gpu") {
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
