{ lib, pkgs, ... }:
let
  inherit (lib) mkDefault;
in
{
  boot = {
    initrd.allowMissingModules = true;
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
  };

  zramSwap.enable = true;
  nixpkgs.hostPlatform = mkDefault "x86_64-linux";

  services.fstrim.enable = true;
}
