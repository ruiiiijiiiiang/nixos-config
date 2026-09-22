{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) task-schedules;
  cfg = config.custom.services.infra.smartd;

  smartdTestSchedule = task-schedules.${config.networking.hostName}.smartd-test or null;
in
{
  options.custom.services.infra.smartd = with lib; {
    enable = mkEnableOption "Enable smartd daemon for monitoring drive health";
    workstation = mkOption {
      type = types.bool;
      default = false;
      description = "Configure smartd for workstation/laptop use (persistent weekly tests on AC power instead of daily scheduled hours)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
      autodetect = true;
      defaults.autodetected =
        if smartdTestSchedule != null then
          "-a -o on -s ${smartdTestSchedule} -n standby"
        else
          "-a -n standby";
    };

    systemd = lib.mkIf cfg.workstation {
      services.smartd-self-test = {
        description = "Run weekly SMART short self-test on all drives";
        unitConfig.ConditionACPower = true;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "smartd-self-test" ''
            ${pkgs.smartmontools}/bin/smartctl --scan | while read -r dev _; do
              if [ -n "$dev" ]; then
                echo "Triggering short SMART test on $dev"
                ${pkgs.smartmontools}/bin/smartctl -t short "$dev" || true
              fi
            done
          '';
        };
      };

      timers.smartd-self-test = {
        description = "Timer to trigger weekly SMART self-tests";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = task-schedules.workstation.smartd-test;
          Persistent = true;
        };
      };
    };
  };
}
