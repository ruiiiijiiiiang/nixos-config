{ config, lib, ... }:
let
  cfg = config.custom.services.apps.location.geoipupdate;
in
{
  options.custom.services.apps.location.geoipupdate = with lib; {
    enable = mkEnableOption "Enable GeoIP updates";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      maxmind-license-key.file = ../../../../../secrets/maxmind-license-key.age;
    };

    services.geoipupdate = {
      enable = true;
      settings = {
        AccountID = 1271453;
        LicenseKey = config.age.secrets.maxmind-license-key.path;
        EditionIDs = [
          "GeoLite2-ASN"
          "GeoLite2-City"
          "GeoLite2-Country"
        ];
      };
    };
  };
}
