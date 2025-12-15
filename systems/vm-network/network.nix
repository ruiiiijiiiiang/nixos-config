{ lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  keys = import ../../lib/keys.nix;
in
with consts;
with keys;
{
  networking = {
    hostName = "rui-nixos-vm-network";
    networkmanager = {
      wifi.powersave = false;
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
      checkReversePath = "loose";
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
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
  users.users.root.openssh.authorizedKeys.keys = ssh.github-action ++ ssh.rui-nixos;
}
