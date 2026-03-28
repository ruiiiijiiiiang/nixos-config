{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) ssh;
  inherit (consts) username ports;
  cfg = config.custom.roles.headless.networking;
in
{
  options.custom.roles.headless.networking = with lib; {
    enable = mkEnableOption "Enable headless networking role";
    trustedInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Interfaces allowed to access exposed ports; empty means global.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (iface: iface != "") cfg.trustedInterfaces;
        message = "trustedInterfaces must not contain empty interface names.";
      }
      {
        assertion = lib.length cfg.trustedInterfaces == lib.length (lib.unique cfg.trustedInterfaces);
        message = "trustedInterfaces must not contain duplicates.";
      }
    ];

    networking = {
      networkmanager = {
        wifi.powersave = false;
      };
      firewall = {
        checkReversePath = "loose";
        logRefusedConnections = true;
        extraInputRules = /* bash */ ''
          iifname "podman*" accept
          iifname "veth*" accept
        '';
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
          AllowTcpForwarding = false;
          X11Forwarding = false;
        };
      };
    };

    users.users = {
      ${username} = {
        linger = true;
        openssh.authorizedKeys.keys = [ ssh.termix ] ++ ssh.arch ++ ssh.framework;
      };

      root.openssh.authorizedKeys.keys = [
        ssh.github-runner
        ssh.forgejo-runner
      ]
      ++ ssh.arch
      ++ ssh.framework;
    };
  };
}
