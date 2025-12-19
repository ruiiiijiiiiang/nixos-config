{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
with lib;
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  sdImage.compressImage = false;

  boot = {
    supportedFilesystems = mkForce [
      "vfat"
      "ext4"
    ];
    kernelPackages = pkgs.linuxPackages_rpi4;
  };

  nixpkgs.hostPlatform = "aarch64-linux";
}
