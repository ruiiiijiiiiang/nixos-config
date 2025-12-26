{ config, lib, ... }:
with lib;
let
  keys = import ../../../lib/keys.nix;
  cfg = config.selfhost.beszel.agent;
in
with keys;
{
  config = mkIf cfg.enable {
    services = {
      beszel.agent = {
        enable = true;
        openFirewall = true;
        environment = {
          KEY = ssh.beszel;
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
