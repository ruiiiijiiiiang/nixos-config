{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  keys = import ../../../lib/keys.nix;
  cfg = config.selfhost.beszel.agent;
in
with consts;
with keys;
{
  config = mkIf cfg.enable {
    services = {
      beszel.agent = {
        enable = true;
        openFirewall = true;
        environment = {
          KEY = ssh.beszel;
          HUB_URL = "https://beszel.${domains.home}";
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
