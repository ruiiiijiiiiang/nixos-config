{ lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  keys = import ../../lib/keys.nix;
in with consts; with keys; {
  networking = {
    hostName = "rui-nixos-pi";
    networkmanager = {
      wifi.powersave = false;
    };
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
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

  services = {
    openssh = {
      enable = true;
      settings = {
        AllowedUsers = "rui";
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "24h";
      ignoreIP = [ addresses.home.network ];
    };
  };

  users.users.rui.openssh.authorizedKeys.keys = ssh.rui-arch ++ ssh.rui-nixos;
}
