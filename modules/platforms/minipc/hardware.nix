{ config, lib, ... }:
let
  cfg = config.custom.platforms.minipc.hardware;
in
{
  options.custom.platforms.minipc.hardware = with lib; {
    enable = mkEnableOption "Minipc hardware config";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      kernelModules = [ "kvm-amd" ];
    };
    hardware.cpu.amd.updateMicrocode = true;
  };
}
