{ lib, pkgs, ... }:
let
  inherit (lib) mkDefault;
  isX86_64 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
{
  boot = {
    initrd.allowMissingModules = true;
    kernelPackages = lib.mkIf isX86_64 (mkDefault pkgs.linuxPackages_latest);
    tmp = {
      useTmpfs = mkDefault true;
      cleanOnBoot = mkDefault true;
    };
  };

  zramSwap.enable = true;
  nixpkgs.hostPlatform = mkDefault "x86_64-linux";

  services.fstrim.enable = mkDefault true;
}
