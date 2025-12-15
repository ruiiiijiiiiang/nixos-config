{ inputs, pkgs, ... }:
with inputs;
{
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    agenix.packages.${stdenv.system}.default
  ];
}
