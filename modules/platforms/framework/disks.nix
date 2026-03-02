{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.platforms.framework.disks;
in
{
  options.custom.platforms.framework.disks = with lib; {
    enable = mkEnableOption "Framework laptop disks config";
  };

  config = lib.mkIf cfg.enable {
    fileSystems = {
      "/boot" = {
        device = "/dev/disk/by-label/NIXBOOT";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      "/" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@"
        ];
      };

      "/home" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@home"
        ];
      };

      "/nix" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@nix"
        ];
      };

      "/tmp" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@tmp"
          "nodatacow"
        ];
      };

      "/var/log" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
        options = [
          "noatime"
          "compress=zstd"
          "ssd"
          "subvol=@log"
          "nodatacow"
        ];
      };
    };

    swapDevices = [
      { device = "/dev/disk/by-label/NIXSWAP"; }
    ];
  };
}
