{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) daily-tasks;
  cfg = config.custom.services.infra.smartd;

  dailyTaskTime = daily-tasks.${config.networking.hostName}.smartd-test or null;

  hour =
    if dailyTaskTime != null then
      let
        parts = lib.splitString ":" dailyTaskTime;
      in
      lib.elemAt parts 0
    else
      null;
in
{
  options.custom.services.infra.smartd = with lib; {
    enable = mkEnableOption "Enable smartd daemon for monitoring drive health";
  };

  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
      autodetect = true;
      defaults.autodetected = if hour != null then "-a -o on -s S/../.././${hour}" else "-a";
    };
  };
}
