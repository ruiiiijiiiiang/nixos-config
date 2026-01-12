{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platform.framework.nixos;
in
{
  options.custom.platform.framework.nixos = with lib; {
    enable = mkEnableOption "Framework-specific NixOS settings";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.flake-update = {
      unitConfig = {
        Description = "Update Nix flakes automatically";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.nix}/bin/nix flake update --flake /home/rui/nixos-config";
        WorkingDirectory = "/home/rui/nixos-config";
      };
      wantedBy = [ "default.target" ];
    };

    systemd.user.timers.flake-update = {
      unitConfig = {
        Description = "Run flake-update daily";
      };
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "flake-update.service";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
