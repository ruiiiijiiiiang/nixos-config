{ consts, utilFns, ... }:
let
  inherit (consts) addresses ports;
  inherit (utilFns) mkHostFqdns;
  hostName = "pi";
  fqdns = mkHostFqdns hostName;
in
{
  networking = {
    inherit hostName;
    hosts = {
      "${addresses.localhost}" = fqdns;
    };
    nftables.tables = {
      "user-rules" = {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority 0; policy accept;
            ip saddr { ${addresses.home.network}, ${addresses.vpn.network} } tcp dport ${toString ports.homeassistant} accept
          }
        '';
      };
    };
  };
}
