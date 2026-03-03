{ lib, pkgs, ... }:
let
  inherit (lib) mkDefault;
in
{
  boot = {
    initrd.allowMissingModules = true;
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    tmp = {
      useTmpfs = mkDefault true;
      cleanOnBoot = mkDefault true;
    };
  };

  zramSwap.enable = true;
  nixpkgs.hostPlatform = mkDefault "x86_64-linux";

  services.fstrim.enable = mkDefault true;
}
