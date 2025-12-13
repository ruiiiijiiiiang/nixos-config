{ ... }:
let
  keys = import ../../lib/keys.nix;
in with keys;
{
  networking = {
    hostName = "rui-nixos-vm";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ]; 
      allowedUDPPorts = [ ];
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
  };

  users.users.rui.openssh.authorizedKeys.keys = ssh.rui-arch ++ ssh.rui-nixos;
}
