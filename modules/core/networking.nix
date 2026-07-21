{ consts, lib, ... }:
let
  inherit (consts) username addresses domain;
  inherit (lib)
    foldl'
    mkDefault
    concatStringsSep
    mapAttrsToList
    ;

  getExtraHosts =
    let
      mergedHosts = foldl' (acc: net: addresses.${net}.hosts // acc) { } [
        "infra"
        "home"
        "dmz"
      ];
      makeHostEntry =
        hostName: ip:
        if lib.hasSuffix "-v6" hostName then
          "${ip} ${hostName} ${lib.removeSuffix "-v6" hostName}"
        else
          "${ip} ${hostName}";
    in
    concatStringsSep "\n" (mapAttrsToList makeHostEntry mergedHosts);
in
{
  networking = {
    inherit domain;
    search = [ domain ];
    networkmanager.enable = mkDefault true;
    firewall.enable = mkDefault true;
    nftables.enable = mkDefault true;
    extraHosts = getExtraHosts;
    useDHCP = mkDefault true;

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

  services.resolved.enable = mkDefault true;

  users.users.${username}.extraGroups = [ "networkmanager" ];
}
