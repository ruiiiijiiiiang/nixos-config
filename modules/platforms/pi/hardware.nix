{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platforms.pi.hardware;
  inherit (consts.hardware) usb-adapter;
in
{
  options.custom.platforms.pi.hardware = with lib; {
    enable = mkEnableOption "Enable Raspberry Pi 4 hardware settings";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        grub.enable = false;
        generic-extlinux-compatible = {
          enable = true;
          useGenerationDeviceTree = true;
        };
      };
      kernelPackages = pkgs.linuxPackages;
      kernelParams = [ "usb-storage.quirks=${usb-adapter.id}:u" ];
    };

    hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "ext4";
        options = [
          "noatime"
          "commit=120"
        ];
      };
    };

    nixpkgs.hostPlatform = "aarch64-linux";

    nix.settings.filter-syscalls = false;

    services.chrony = {
      enableRTCTrimming = false;
    };
  };
}
