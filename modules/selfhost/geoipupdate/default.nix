{ config, lib, ... }:
let
  cfg = config.custom.selfhost.geoipupdate;
in
{
  options.custom.selfhost.geoipupdate = with lib; {
    enable = mkEnableOption "GeoIP update by Maxmind";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      geoip-env.file = ../../../secrets/geoip-env.age;
    };

    services.geoipupdate = {
      enable = true;
      settings = {
        AccountID = 1271453;
        LicenseKey = config.age.secrets.geoip-env.path;
        EditionIDs = [
          "GeoLite2-ASN"
          "GeoLite2-City"
          "GeoLite2-Country"
        ];
      };
    };
  };
}
