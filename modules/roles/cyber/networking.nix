{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) ssh;
  inherit (consts) username home;
  cfg = config.custom.roles.cyber.networking;
in
{
  options.custom.roles.cyber.networking = with lib; {
    enable = mkEnableOption "Cyber role networking config";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      firewall.enable = false;
      nftables.enable = false;
      networkmanager = {
        plugins = with pkgs; [
          networkmanager-openvpn
        ];
      };
    };

    services = {
      openvpn.servers.tryhackme = {
        config = "config ${home}/tryhackme/tryhackme.ovpn";
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
