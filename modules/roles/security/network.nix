{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ../../../lib/keys.nix) ssh;
  inherit (consts) home;
  cfg = config.custom.roles.security.network;
in
{
  options.custom.roles.security.network = with lib; {
    enable = mkEnableOption "Security role network config";
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

    users.users.rui.openssh.authorizedKeys.keys = ssh.rui-arch ++ ssh.framework;
    users.users.root.openssh.authorizedKeys.keys = [
      ssh.github-action
    ]
    ++ ssh.rui-arch
    ++ ssh.framework;
  };
}
