{ lib }:
hostName:
let
  inherit (import ./consts.nix) domains subdomains;
  hostSubdomainsSet = subdomains.${hostName} or { };
  hostSubdomainList = lib.attrValues hostSubdomainsSet;
in
map (sub: "${sub}.${domains.home}") hostSubdomainList
