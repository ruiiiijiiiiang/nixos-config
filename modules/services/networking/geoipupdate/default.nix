{ config, lib, ... }:
let
  cfg = config.custom.services.networking.geoipupdate;
in
{
  options.custom.services.networking.geoipupdate = with lib; {
    enable = mkEnableOption "GeoIP update by Maxmind";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      geoip-key.file = ../../../../secrets/geoip-key.age;
    };

    services.geoipupdate = {
      enable = true;
      settings = {
        AccountID = 1271453;
        LicenseKey = config.age.secrets.geoip-key.path;
        EditionIDs = [
          "GeoLite2-ASN"
          "GeoLite2-City"
          "GeoLite2-Country"
        ];
      };
    };
  };
}
