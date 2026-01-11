{ config, lib, ... }:
let
  inherit (lib) mkIf mkForce;
  inherit (import ../../../lib/consts.nix) domains;
  inherit (import ../../../lib/keys.nix) ssh;
  cfg = config.custom.selfhost.beszel.agent;
in
{
  options.custom.selfhost.beszel.agent = with lib; {
    enable = mkEnableOption "Beszel monitoring agent";
  };

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
