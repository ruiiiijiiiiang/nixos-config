{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) ssh;
  inherit (consts) ports;
  cfg = config.custom.roles.headless.network;
in
{
  options.custom.roles.headless.network = with lib; {
    enable = mkEnableOption "Custom network setup for servers";
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Interfaces to open ports. If empty, ports are open globally.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        wifi.powersave = false;
      };
      firewall =
        {
          enable = true;
          checkReversePath = "loose";
          trustedInterfaces = [ "podman0" ];
          logRefusedConnections = true;
        }
        // (
          if cfg.interfaces != [ ] then
            {
              interfaces = lib.genAttrs cfg.interfaces (iface: {
                allowedTCPPorts = [
                  ports.ssh
                  ports.http
                  ports.https
                ];
              });
            }
          else
            {
              allowedTCPPorts = [
                ports.ssh
                ports.http
                ports.https
              ];
            }
        );
      nat = {
        enable = true;
        internalInterfaces = [ "podman0" ];
      };
    };

    services = {
      openssh = {
        enable = true;
        openFirewall = false;
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
    users.users.root.openssh.authorizedKeys.keys = [
      ssh.github-action
    ]
    ++ ssh.rui-arch
    ++ ssh.framework;
  };
}
