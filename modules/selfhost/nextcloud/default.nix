{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.nextcloud;
  fqdn = "${consts.subdomains.${config.networking.hostName}.nextcloud}.${consts.domains.home}";
  office-fqdn = "${
    consts.subdomains.${config.networking.hostName}.onlyoffice
  }.${consts.domains.home}";
in
with consts;
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
        hostName = fqdn;
        https = true;

        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
          adminpassFile = config.age.secrets.nextcloud-pass.path;
          adminuser = "admin";
        };

        configureRedis = true;

        maxUploadSize = "16G";
        phpOptions = {
          "opcache.interned_strings_buffer" = "16";
        };

        extraAppsEnable = true;
        extraApps = with config.services.nextcloud.package.packages.apps; {
          inherit onlyoffice;
          inherit notes;
        };
        autoUpdateApps.enable = true;
        settings = {
          allow_local_remote_servers = true;
          trusted_domains = [ fqdn ];
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = [ "nextcloud" ];
        ensureUsers = [
          {
            name = "nextcloud";
            ensureDBOwnership = true;
          }
        ];
      };

      redis.servers.nextcloud = {
        enable = true;
        port = 0;
        unixSocket = "/run/redis-nextcloud/redis.sock";
        user = "nextcloud";
        group = "nextcloud";
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
        "${fqdn}" = {
          useACMEHost = fqdn;
          forceSSL = true;
        };

        "${office-fqdn}" = {
          useACMEHost = office-fqdn;
          forceSSL = true;
        };
      };
    };

    systemd.services.onlyoffice-docservice = {
      after = [ "agenix.service" ];
      wants = [ "agenix.service" ];
    };
  };
}
