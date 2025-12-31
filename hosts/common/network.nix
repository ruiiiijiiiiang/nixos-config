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
    extraHosts = concatStringsSep "\n" (mapAttrsToList makeHostEntry addresses.home.hosts);
    useDHCP = mkDefault true;
    networkmanager.enable = mkDefault true;
  };

  services.resolved.enable = mkDefault true;
}
