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
      kernelModules = [
        "kvm-amd"
        "vhost_net"
        "vhost_vsock"
      ];
    };
    hardware.cpu.amd.updateMicrocode = true;
  };
}
