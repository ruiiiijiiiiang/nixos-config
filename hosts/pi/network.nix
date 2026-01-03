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
    firewall = {
      extraCommands = ''
        iptables -A nixos-fw -p tcp --source ${addresses.home.network} --dport ${toString ports.homeassistant} -j nixos-fw-accept
        iptables -A nixos-fw -p tcp --source ${addresses.vpn.network} --dport ${toString ports.homeassistant} -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p tcp --source ${addresses.home.network} --dport ${toString ports.homeassistant} -j nixos-fw-accept || true
        iptables -D nixos-fw -p tcp --source ${addresses.vpn.network} --dport ${toString ports.homeassistant} -j nixos-fw-accept || true
      '';
    };
  };
}
