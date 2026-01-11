{ config, lib, ... }:
let
  inherit (import ../../lib/keys.nix) ssh;
  cfg = config.custom.server.network;
in
{
  options.custom.server.network = with lib; {
    enable = mkEnableOption "Custom network setup for servers";
  };

  config = lib.mkIf cfg.enable {
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
        checkReversePath = "loose";
        trustedInterfaces = [ "podman0" ];
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
  };
}
