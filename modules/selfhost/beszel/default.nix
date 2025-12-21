{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.beszel;
  fqdn = "${consts.subdomains.${config.networking.hostName}.beszel}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      beszel-key.file = ../../../secrets/beszel-key.age;
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

      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.beszel.hub}";
          proxyWebsockets = true;
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

    users = {
      groups.beszel = { };
      users.beszel = {
        isSystemUser = true;
        group = "beszel";
        extraGroups = [ "podman" ];
      };
    };
  };
}
