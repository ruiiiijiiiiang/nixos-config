{ config, lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  cfg = config.selfhost.paperless;
  fqdn = "${consts.subdomains.${config.networking.hostName}.paperless}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    services = {
      paperless = {
        enable = true;
        address = addresses.localhost;
        port = ports.paperless;
        mediaDir = "/var/storage/paperless/media";
        consumptionDir = "/var/storage/paperless/consume";
        passwordFile = "/var/lib/paperless/admin-pass";

        settings = {
          PAPERLESS_URL = "https://${fqdn}";
          PAPERLESS_TIME_ZONE = "America/Chicago";
          PAPERLESS_OCR_CLEAN = "clean";
          PAPERLESS_OCR_DESKEW = true;
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_FILENAME_FORMAT = "{created_year}/{correspondent}/{title}";
        };
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.paperless}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Connection "upgrade";
            proxy_set_header Upgrade $http_upgrade;
            client_max_body_size 100M;
          '';
        };
      };
    };
  };
}
