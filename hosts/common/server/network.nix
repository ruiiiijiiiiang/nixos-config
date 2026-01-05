let
  inherit (import ../../../lib/keys.nix) ssh;
in
{
  networking = {
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
      allowedUDPPorts = [ ];
      checkReversePath = "loose";
    };
    nat = {
      enable = true;
      internalInterfaces = [ "podman0" ];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        KbdInteractiveAuthentication = false;
        AllowTcpForwarding = "no";
        X11Forwarding = false;
      };
    };
  };

  users.users.rui.openssh.authorizedKeys.keys = ssh.rui-arch ++ ssh.framework;
  users.users.root.openssh.authorizedKeys.keys = [ ssh.github-action ] ++ ssh.framework;
}
