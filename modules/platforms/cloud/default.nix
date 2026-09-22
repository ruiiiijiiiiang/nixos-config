{ lib, ... }:
{
  boot.tmp.cleanOnBoot = true;

  networking = {
    networkmanager.enable = lib.mkForce false;
    useDHCP = lib.mkDefault true;
  };

  services.resolved.settings.Resolve = {
    LLMNR = false;
    MulticastDNS = false;
  };

  services.journald.settings.Journal.SystemMaxUse = lib.mkForce "256M";

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
}
