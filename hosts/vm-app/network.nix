{ consts, utilFns, ... }:
let
  inherit (consts) addresses;
  inherit (utilFns) mkHostFqdns;
  hostName = "vm-app";
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
