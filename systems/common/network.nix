{ lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
in with consts; {
  networking = {
    extraHosts = ''
      ${addresses.home.hosts.arch} arch
      ${addresses.home.hosts.nixos} nixos
      ${addresses.home.hosts.pi} pi
      ${addresses.home.hosts.pi} public.${domains.home}
      ${addresses.home.hosts.pi} monit.${domains.home}
      ${addresses.home.hosts.pi} atuin.${domains.home}
      ${addresses.home.hosts.pi} ha.${domains.home}
      ${addresses.home.hosts.pi} zwave.${domains.home}
      ${addresses.home.hosts.pi} microbin.${domains.home}
      ${addresses.home.hosts.pi} pihole.${domains.home}
      ${addresses.home.hosts.pi} syncthing.${domains.home}
      ${addresses.home.hosts.pi} vault.${domains.home}
    '';
    useDHCP = mkDefault true;
    networkmanager.enable = mkDefault true;
  };

  services.resolved.enable = mkDefault true;
}
