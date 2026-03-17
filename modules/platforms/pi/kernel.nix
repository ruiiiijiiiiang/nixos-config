{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platforms.pi.kernel;
in
{
  options.custom.platforms.pi.kernel = with lib; {
    enable = mkEnableOption "Enable Raspberry Pi 4 kernel settings";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
      kernelPackages = pkgs.linuxPackages_rpi4;

      supportedFilesystems = [
        "vfat"
        "ext4"
      ];
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
