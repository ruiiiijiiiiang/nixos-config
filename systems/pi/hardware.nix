{ lib, pkgs, ... }:
with lib;
{
  boot = {
    supportedFilesystems = mkForce [ "vfat" "ext4" ];
    kernelPackages = pkgs.linuxPackages_rpi4;
    initrd.allowMissingModules = true;
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
