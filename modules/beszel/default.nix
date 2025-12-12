{ config, lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  cfg = config.rui.beszel;
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      beszel-key.file = ../../secrets/beszel-key.age;
    };

    services = {
      beszel = {
        hub = {
          enable = true;
          port = ports.beszel.hub;
        };

        agent = {
          enable = true;
          environmentFile = config.age.secrets.beszel-key.path;
        };
      };

      nginx.virtualHosts."beszel.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.beszel.hub}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };

    systemd.services.beszel-agent.serviceConfig = {
      User = mkForce "root";
      Group = mkForce "root";
      DynamicUser = mkForce false;
      PrivateMounts = mkForce false;
      PrivateDevices = mkForce false;
      ProtectHome = mkForce true;
      ProtectSystem = mkForce "strict";
    };

    users.users.beszel = {
      isSystemUser = true;
      group = "beszel";
      extraGroups = [ "podman" ];
    };
    users.groups.beszel = { };
  };
}
