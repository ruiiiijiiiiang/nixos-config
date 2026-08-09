{
  config,
  consts,
  inputs,
  keys,
  lib,
  ...
}:
let
  cfg = config.custom.roles.headless.services;
  inherit (consts) username;
  inherit (keys) ssh;
  termixEnabled =
    inputs.self.nixosConfigurations.vm-monitor.config.custom.services.observability.termix.enable;
in
{
  options.custom.roles.headless.services = with lib; {
    enable = mkEnableOption "Enable headless services role";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      variables = {
        EDITOR = "vim";
      };
    };

    services = {
      logrotate.enable = true;
      journald.extraConfig = ''
        SystemMaxUse=1G
        Storage=persistent
      '';

      xserver.enable = false;
      printing.enable = false;
      avahi.enable = lib.mkDefault false;

      openssh = {
        enable = true;
        openFirewall = false;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "prohibit-password";
          KbdInteractiveAuthentication = false;
          AllowTcpForwarding = false;
          X11Forwarding = false;
          HostbasedAuthentication = false;
          IgnoreRhosts = true;
          PermitEmptyPasswords = false;
          PermitUserEnvironment = false;
        };
      };
    };

    users.users = {
      ${username} = {
        linger = true;
        openssh.authorizedKeys.keys =
          lib.optionals termixEnabled [ ssh.termix ] ++ ssh.desktop ++ ssh.framework ++ ssh.windows;
      };

      root.openssh.authorizedKeys.keys = [
        ssh.github-runner
        ssh.forgejo-runner
      ]
      ++ ssh.desktop
      ++ ssh.framework
      ++ ssh.windows;
    };
  };
}
