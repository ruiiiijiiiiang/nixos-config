{ config, lib, ... }:
with lib;
let
  cfg = config.rui.vaultwarden;
  consts = import ../../lib/consts.nix;
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      vaultwarden-env.file = ../../secrets/vaultwarden-env.age;
    };

    services = {
      vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        environmentFile = config.age.secrets.vaultwarden-env.path;

        config = {
          DOMAIN = "https://vault.${domains.home}";
          SIGNUPS_ALLOWED = false;

          ROCKET_ADDRESS = addresses.localhost;
          ROCKET_PORT = ports.vaultwarden.server;

          WEBSOCKET_ENABLED = true;
          WEBSOCKET_ADDRESS = addresses.localhost;
          WEBSOCKET_PORT = ports.vaultwarden.websocket;
        };
      };

      nginx.virtualHosts."vault.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.vaultwarden.server}";
        };
        locations."/notifications/hub" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.vaultwarden.websocket}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };
}
