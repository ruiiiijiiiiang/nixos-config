{ lib, consts, ... }:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ;
in
{
  mkHostFqdns =
    hostName:
    let
      hostSubdomainsSet = subdomains.${hostName} or { };
      hostSubdomainList = lib.attrValues hostSubdomainsSet;
    in
    map (sub: "${sub}.${domains.home}") hostSubdomainList;

  mkVirtualHost =
    {
      fqdn,
      port,
      proxyWebsockets ? false,
      extraConfig ? "",
    }:
    {
      useACMEHost = fqdn;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString port}";
        inherit proxyWebsockets;
        inherit extraConfig;
      };
    };
}
