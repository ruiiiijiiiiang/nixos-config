{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (import ../../../../lib/keys.nix) ssh;
  inherit (consts) username;
  cfg = config.custom.roles.workstation.cyber.networking;
in
{
  options.custom.roles.workstation.cyber.networking = with lib; {
    enable = mkEnableOption "Enable cyber role networking";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      tryhackme-ovpn.file = ../../../../secrets/tryhackme-ovpn.age;
    };

    networking = {
      firewall.enable = false;
      nftables.enable = false;
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
    };

    users.users.${username}.openssh.authorizedKeys.keys = ssh.arch ++ ssh.framework;
    users.users.root.openssh.authorizedKeys.keys = [
      ssh.github-runner
      ssh.forgejo-runner
    ]
    ++ ssh.arch
    ++ ssh.framework;
  };
}
