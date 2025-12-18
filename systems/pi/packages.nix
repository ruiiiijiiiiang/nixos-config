{ inputs, pkgs, ... }:
with inputs;
{
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    agenix.packages.${stdenv.system}.default
  ];
  # raspberrypi-eeprom is used to update the pi firmware,
  # but since nixos has a different filesystem structure,
  # the firmware partition must be manually mounted first
  # sudo mount /dev/disk/by-label/FIRMWARE /mnt
  # sudo BOOTFS=/mnt rpi-eeprom-update -a
}
