{ consts, lib, ... }:
let
  inherit (lib)
    attrValues
    concatStringsSep
    mkDefault
    mapAttrsToList
    ;
  inherit (consts) addresses domains subdomains;
  makeHostEntry =
    hostName: ip:
    let
      hostSubdomainsSet = subdomains.${hostName} or { };
      hostSubdomainList = attrValues hostSubdomainsSet;
      fqdns = map (sub: "${sub}.${domains.home}") hostSubdomainList;
      allNames = [ hostName ] ++ fqdns;
    in
    "${ip} ${concatStringsSep " " allNames}";
in
{
  networking = {
    nftables.enable = mkDefault true;
    extraHosts = concatStringsSep "\n" (mapAttrsToList makeHostEntry addresses.home.hosts);
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

  services.resolved.enable = mkDefault true;
}
