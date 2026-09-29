{ config, lib, ... }:
let
  cfg = config.custom.platforms.cloud;
in
{
  options.custom.platforms.cloud = {
    enable = lib.mkEnableOption "Enable shared cloud platform settings";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
