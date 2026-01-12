{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platform.pi.packages;
in
{
  options.custom.platform.pi.packages = with lib; {
    enable = mkEnableOption "Raspberry Pi-specific packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libraspberrypi
      raspberrypi-eeprom
    ];
    # raspberrypi-eeprom is used to update the pi firmware,
    # but since nixos has a different filesystem structure,
    # the firmware partition must be manually mounted first
    # sudo mount /dev/disk/by-label/FIRMWARE /mnt
    # sudo BOOTFS=/mnt rpi-eeprom-update -a
  };
}
