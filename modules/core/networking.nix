{ consts, lib, ... }:
let
  inherit (consts) addresses username;
  inherit (lib) mkDefault;
  getExtraHosts =
    let
      inherit (lib) concatStringsSep mapAttrsToList;
      mergedHosts = builtins.foldl' (acc: net: addresses.${net}.hosts // acc) { } [
        "infra"
        "home"
        "dmz"
      ];
      makeHostEntry = hostName: ip: "${ip} ${hostName}";
    in
    concatStringsSep "\n" (mapAttrsToList makeHostEntry mergedHosts);
in
{
  networking = {
    nftables.enable = mkDefault true;
    extraHosts = getExtraHosts;
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
