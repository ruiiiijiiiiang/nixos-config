{ lib, ... }:
{
  imports = [
    ./hardware.nix
    ./disks.nix
  ];

  options.custom.vm = with lib; {
    hardware = {
      enable = mkEnableOption "Custom hardware config for vm";
    };
    disks = {
      enableMain = mkEnableOption "Enable main drive (scsi0)";
      enableStorage = mkEnableOption "Enable storage drive (scsi1)";
      enableScratch = mkEnableOption "Enable scratch drive (scsi2)";
    };
  };
}
