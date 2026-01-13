{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platform.pi.hardware;
in
{
  options.custom.platform.pi.hardware = with lib; {
    enable = mkEnableOption "Raspberry Pi 4 hardware config";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };

      supportedFilesystems = lib.mkForce [
        "vfat"
        "ext4"
      ];
      kernelPackages = pkgs.linuxPackages_rpi4;
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "noatime" ];
      };
    };

    nixpkgs.hostPlatform = "aarch64-linux";
  };
}
