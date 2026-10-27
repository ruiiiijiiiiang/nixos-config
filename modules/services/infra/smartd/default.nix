{ config, lib, ... }:
let
  cfg = config.custom.services.infra.smartd;
in
{
  options.custom.services.infra.smartd = with lib; {
    enable = mkEnableOption "Enable smartd daemon for monitoring drive health";
  };

  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
      autodetect = true;
      defaults.autodetected = "-a -n standby";
    };
  };
}
