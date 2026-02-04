{ consts, lib, helpers, ... }:
let
  inherit (consts) username;
  inherit (lib) mkDefault;
  inherit (helpers) mkExtraHosts;
in
{
  networking = {
    nftables.enable = mkDefault true;
    extraHosts = mkExtraHosts;
    useDHCP = mkDefault true;
    networkmanager.enable = mkDefault true;

    timeServers = [
      "162.159.200.1"
      "162.159.200.123"
      "8.8.8.8"
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
  };

  users.users.${username}.extraGroups = [ "networkmanager" ];

  services.resolved.enable = mkDefault true;
}
