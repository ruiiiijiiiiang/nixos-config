{
  secretsDir,
  config,
  consts,
  keys,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) username;
  inherit (keys) ssh;
  cfg = config.custom.roles.workstation.cyber.services;
in
{
  options.custom.roles.workstation.cyber.services = with lib; {
    enable = mkEnableOption "Enable cyber role services";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      tryhackme-ovpn.file = secretsDir + "/personal/tryhackme/client.ovpn.age";
    };

    services = {
      openvpn.servers.tryhackme = {
        config = "config ${config.age.secrets.tryhackme-ovpn.path}";
      };

      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = false;
        };
      };

      xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
        desktopManager.lxqt.enable = true;
      };

      pipewire.enable = false;
      pulseaudio.enable = true;

      postgresql = {
        enable = true;
        ensureDatabases = [ "msf" ];
        ensureUsers = [
          {
            name = "msf";
            ensureDBOwnership = true;
          }
        ];
        identMap = ''
          msf_map ${username} msf
        '';
        authentication = pkgs.lib.mkOverride 10 ''
          local all all peer map=msf_map
        '';
      };

      vnstat.enable = true;
    };

    xdg.portal = {
      enable = true;
      config.common.default = [ "gtk" ];
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    users.users.${username}.openssh.authorizedKeys.keys = ssh.desktop ++ ssh.framework;
    users.users.root.openssh.authorizedKeys.keys = [
      ssh.github-runner
      ssh.forgejo-runner
    ]
    ++ ssh.desktop
    ++ ssh.framework;
  };
}
