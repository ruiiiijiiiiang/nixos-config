{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.roles.workstation.cyber.packages;
in
{
  options.custom.roles.workstation.cyber.packages = with lib; {
    enable = mkEnableOption "Enable cyber role packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      seclists
    ];

    programs = {
      nix-ld.enable = true;
      wireshark.enable = true;
    };

    systemd.tmpfiles.rules = [
      "L /home/${username}/wordlists - - - - /run/current-system/sw/share/wordlists"
    ];
  };
}
