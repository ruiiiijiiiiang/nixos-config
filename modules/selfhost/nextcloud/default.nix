{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (import ../../../lib/consts.nix) domains subdomains ports;
  cfg = config.selfhost.nextcloud;
  nextcloud-fqdn = "${subdomains.${config.networking.hostName}.nextcloud}.${domains.home}";
  office-fqdn = "${subdomains.${config.networking.hostName}.onlyoffice}.${domains.home}";
in
{
  config = mkIf cfg.enable {
    age.secrets = {
      nextcloud-pass.file = ../../../secrets/nextcloud-pass.age;
      onlyoffice-secret = {
        file = ../../../secrets/onlyoffice-secret.age;
        owner = "onlyoffice";
        group = "onlyoffice";
        mode = "0400";
      };
    };

    services = {
      nextcloud = {
        enable = true;
        hostName = nextcloud-fqdn;
        https = true;
        config = {
          dbtype = "pgsql";
          adminpassFile = config.age.secrets.nextcloud-pass.path;
          adminuser = "admin";
        };

        database.createLocally = true;
        configureRedis = true;

        maxUploadSize = "16G";
        phpOptions = {
          "opcache.interned_strings_buffer" = "16";
        };
        phpExtraExtensions = all: [ all.apcu ];

        extraAppsEnable = true;
        extraApps = with config.services.nextcloud.package.packages.apps; {
          inherit onlyoffice;
          inherit notes;
          inherit theming_customcss;
          inherit sociallogin;
        };
        autoUpdateApps.enable = true;
        settings = {
          allow_local_remote_servers = true;
          trusted_domains = [ nextcloud-fqdn ];
          "memcache.local" = "\\OC\\Memcache\\APCu";
        };
      };

      onlyoffice = {
        enable = true;
        hostname = office-fqdn;
        port = ports.onlyoffice;
        wopi = true;
        jwtSecretFile = config.age.secrets.onlyoffice-secret.path;
        securityNonceFile = "${pkgs.writeText "onlyoffice-nonce.conf" ''
          set $secure_link_secret "oiabUbY4xiQAYsi54Kz9IeJBzP2vRm3E2sK5scF5";
        ''}";
      };

      nginx.virtualHosts = {
        "${nextcloud-fqdn}" = {
          useACMEHost = nextcloud-fqdn;
          forceSSL = true;
        };

        "${office-fqdn}" = {
          useACMEHost = office-fqdn;
          forceSSL = true;
        };
      };
    };

    systemd.services = {
      onlyoffice-docservice = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
      };
    };
  };
}
