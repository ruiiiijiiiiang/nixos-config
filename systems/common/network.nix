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
      ${addresses.home.hosts.pi.ethernet} pi-monit.${domains.home}
      ${addresses.home.hosts.pi.ethernet} pdf.${domains.home}
      ${addresses.home.hosts.pi.ethernet} pi-pihole.${domains.home}
      ${addresses.home.hosts.pi.ethernet} portainer.${domains.home}
      ${addresses.home.hosts.pi.ethernet} public.${domains.home}
      ${addresses.home.hosts.pi.ethernet} syncthing.${domains.home}
      ${addresses.home.hosts.pi.ethernet} vault.${domains.home}
      ${addresses.home.hosts.pi.ethernet} zwave.${domains.home}

      ${addresses.home.hosts.vm-network} vm-network
      ${addresses.home.hosts.vm-network} pihole.${domains.home}
      ${addresses.home.hosts.vm-network} vm-network-monit.${domains.home}

      ${addresses.home.hosts.vm-app} vm-app
    '';
    useDHCP = mkDefault true;
    networkmanager.enable = mkDefault true;
  };

  services.resolved.enable = mkDefault true;
}
