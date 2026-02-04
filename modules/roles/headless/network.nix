{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) ssh;
  inherit (consts) username ports;
  cfg = config.custom.roles.headless.network;
in
{
  options.custom.roles.headless.network = with lib; {
    enable = mkEnableOption "Custom network setup for servers";
    podmanInterface = mkOption {
      type = types.str;
      default = "podman0";
      description = "Interface for podman";
    };
    trustedInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Interfaces to open ports; if empty, ports are open globally";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager = {
        wifi.powersave = false;
      };
      firewall = {
        enable = true;
        checkReversePath = "loose";
        trustedInterfaces = [ cfg.podmanInterface ];
        logRefusedConnections = true;
      }
      // (
        if cfg.trustedInterfaces != [ ] then
          {
            interfaces = lib.genAttrs cfg.trustedInterfaces (iface: {
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
        internalInterfaces = [ cfg.podmanInterface ];
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

    users.users.${username}.openssh.authorizedKeys.keys = ssh.arch ++ ssh.framework;
    users.users.root.openssh.authorizedKeys.keys = [
      ssh.github-action
    ]
    ++ ssh.arch
    ++ ssh.framework;
  };
}
