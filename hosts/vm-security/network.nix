{ pkgs, ... }:
let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  networking = {
    hostName = "vm-security";
    networkmanager = {
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };
  };

  services = {
    openvpn.servers.tryhackme = {
      config = "config /home/rui/tryhackme/tryhackme.ovpn";
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };
  };

  users.users.rui.openssh.authorizedKeys.keys = ssh.rui-arch ++ ssh.framework;
  users.users.root.openssh.authorizedKeys.keys = ssh.framework;
}
