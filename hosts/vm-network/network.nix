{ consts, lib, ... }:
let
  inherit (consts) addresses;
  mkHostFqdns = import ../../lib/mkHostFqdns.nix { inherit lib; };
  hostName = "vm-network";
  fqdns = mkHostFqdns hostName;
in
{
  networking = {
    inherit hostName;
    hosts = {
      "${addresses.localhost}" = fqdns;
    };
  };
}
