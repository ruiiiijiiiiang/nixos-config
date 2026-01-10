{ lib, consts, pkgs, ... }:
let
  inherit (consts)
    addresses
    macs
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

  mkReservations =
    let
      inherit (addresses.home) hosts;
    in
    builtins.map (hostname: {
      hw-address = macs.${hostname};
      ip-address = hosts.${hostname};
      inherit hostname;
    }) (builtins.filter (hostname: builtins.hasAttr hostname hosts) (builtins.attrNames macs));

  syncFile = { source, destination, user ? "root", group ? "root", mode ? "640" }: ''
    mkdir -p "$(dirname "${destination}")"

    if [ ! -f "${destination}" ] || ! ${pkgs.diffutils}/bin/cmp -s "${source}" "${destination}"; then
      echo "Updating content for ${destination}..."
      cat "${source}" > "${destination}"
    else
      echo "${destination} already exists. Skipping initialization."
    fi

    chown ${user}:${group} "${destination}"
    chmod ${mode} "${destination}"
  '';
}
