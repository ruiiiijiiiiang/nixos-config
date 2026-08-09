{ config, lib, ... }:
let
  cfg = config.custom.roles.workstation.cyber.networking;
in
{
  options.custom.roles.workstation.cyber.networking = with lib; {
    enable = mkEnableOption "Enable cyber role networking";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      firewall.enable = false;
      nftables.enable = false;
    };

    environment.etc.hosts.mode = "0644";
  };
}
