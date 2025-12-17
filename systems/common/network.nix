{ lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  makeHostEntry =
    hostname: ip:
    let
      hostSubdomainsSet = consts.subdomains.${hostname} or { };
      hostSubdomainList = attrValues hostSubdomainsSet;
      fqdns = map (sub: "${sub}.${consts.domains.home}") hostSubdomainList;
      allNames = [ hostname ] ++ fqdns;
    in
    "${ip} ${lib.concatStringsSep " " allNames}";
in
with consts;
{
  networking = {
    extraHosts = concatStringsSep "\n" (mapAttrsToList makeHostEntry addresses.home.hosts);
    useDHCP = mkDefault true;
    networkmanager.enable = mkDefault true;
  };

  services.resolved.enable = mkDefault true;
}
