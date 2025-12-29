{ consts, lib, ... }:
with consts;
with lib;
let
  makeHostEntry =
    hostname: ip:
    let
      hostSubdomainsSet = subdomains.${hostname} or { };
      hostSubdomainList = attrValues hostSubdomainsSet;
      fqdns = map (sub: "${sub}.${domains.home}") hostSubdomainList;
      allNames = [ hostname ] ++ fqdns;
    in
    "${ip} ${lib.concatStringsSep " " allNames}";
in
{
  networking = {
    extraHosts = concatStringsSep "\n" (mapAttrsToList makeHostEntry addresses.home.hosts);
    useDHCP = mkDefault true;
    networkmanager.enable = mkDefault true;
  };

  services.resolved.enable = mkDefault true;
}
