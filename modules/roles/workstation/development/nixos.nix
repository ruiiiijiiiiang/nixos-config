{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) home;
  cfg = config.custom.roles.workstation.development.nixos;
in
{
  options.custom.roles.workstation.development.nixos = with lib; {
    enable = mkEnableOption "Enable development NixOS settings";
  };

  config = lib.mkIf cfg.enable {
    systemd.user = {
      services.flake-update = {
        unitConfig = {
          Description = "Update Nix flakes automatically";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.nix}/bin/nix flake update --flake ${home}/nixos-config";
          WorkingDirectory = "${home}/nixos-config";
        };
        wantedBy = [ "default.target" ];
      };

      timers.flake-update = {
        unitConfig = {
          Description = "Run flake-update daily";
        };
        timerConfig = {
          OnCalendar = "daily";
          Unit = "flake-update.service";
        };
        wantedBy = [ "timers.target" ];
      };
    };
  };
}
