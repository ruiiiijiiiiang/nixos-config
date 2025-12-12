{ lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
in
with consts;
{
  networking = {
    extraHosts = ''
      ${addresses.home.hosts.arch} arch
      ${addresses.home.hosts.nixos} nixos
      ${addresses.home.hosts.pi.ethernet} pi
      ${addresses.home.hosts.pi.ethernet} atuin.${domains.home}
      ${addresses.home.hosts.pi.ethernet} beszel.${domains.home}
      ${addresses.home.hosts.pi.ethernet} bin.${domains.home}
      ${addresses.home.hosts.pi.ethernet} ha.${domains.home}
      ${addresses.home.hosts.pi.ethernet} monit.${domains.home}
      ${addresses.home.hosts.pi.ethernet} pdf.${domains.home}
      ${addresses.home.hosts.pi.ethernet} pihole.${domains.home}
      ${addresses.home.hosts.pi.ethernet} portainer.${domains.home}
      ${addresses.home.hosts.pi.ethernet} public.${domains.home}
      ${addresses.home.hosts.pi.ethernet} syncthing.${domains.home}
      ${addresses.home.hosts.pi.ethernet} vault.${domains.home}
      ${addresses.home.hosts.pi.ethernet} zwave.${domains.home}
    '';
    useDHCP = mkDefault true;
    networkmanager.enable = mkDefault true;
  };

  services.resolved.enable = mkDefault true;
}
