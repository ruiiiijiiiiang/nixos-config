{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platforms.pi.hardware;
in
{
  options.custom.platforms.pi.hardware = with lib; {
    enable = mkEnableOption "Enable Raspberry Pi 4 hardware settings";
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
        options = [
          "noatime"
          "commit=120"
        ];
      };
    };

    nixpkgs.hostPlatform = "aarch64-linux";
  };
}
