{ config, lib, ... }:
let
  inherit (import ../../../../lib/consts.nix) addresses;
  cfg = config.custom.services.security.fail2ban;
in
{
  options.custom.services.security.fail2ban = with lib; {
    enable = mkEnableOption "Fail2ban IPS";
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      bantime = "1h";
      maxretry = 5;
      ignoreIP = [
        addresses.home.network
        addresses.infra.network
        addresses.vpn.network
      ];

      jails = {
        DEFAULT = {
          settings = {
            findtime = "10m";
          };
        };

        sshd = {
          settings = {
            mode = "aggressive";
            port = "ssh";
          };
        };

        recidive = {
          settings = {
            enabled = true;
            backend = "systemd";
            journalmatch = "_SYSTEMD_UNIT=fail2ban.service";
            banaction = "%(banaction_allports)s";
            maxretry = 5;
            findtime = "1d";
            bantime = "1w";
          };
        };
      };
    };
  };
}
