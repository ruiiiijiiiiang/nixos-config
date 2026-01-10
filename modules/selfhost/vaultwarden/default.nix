{ config, lib, ... }:
let
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.custom.selfhost.vaultwarden;
  fqdn = "${subdomains.${config.networking.hostName}.vaultwarden}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      vaultwarden-env.file = ../../../secrets/vaultwarden-env.age;
      # ADMIN_TOKEN=FKVOLl/pFRQiaoImf0ubhxJwaKz13iCkza8ptZD5almg3EOL8eJkOUPzOtOWxWOF
      # SMTP_HOST
      # SMTP_PORT
      # SMTP_SECURITY
      # SMTP_USERNAME
      # SMTP_PASSWORD
      # SMTP_FROM
      # SMTP_FROM_NAME
    };

    services = {
      vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        environmentFile = config.age.secrets.vaultwarden-env.path;

        config = {
          DOMAIN = "https://${fqdn}";
          SIGNUPS_ALLOWED = false;

          ROCKET_ADDRESS = addresses.localhost;
          ROCKET_PORT = ports.vaultwarden.server;

          WEBSOCKET_ENABLED = true;
          WEBSOCKET_ADDRESS = addresses.localhost;
          WEBSOCKET_PORT = ports.vaultwarden.websocket;
        };
      };

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.vaultwarden.server}";
        };
        locations."/notifications/hub" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.vaultwarden.websocket}";
        };
      };
    };
  };
}
