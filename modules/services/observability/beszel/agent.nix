{ config, lib, ... }:
let
  inherit (lib) mkIf mkForce;
  inherit (import ../../../../lib/consts.nix) domain ports;
  inherit (import ../../../../lib/keys.nix) ssh;
  cfg = config.custom.services.observability.beszel.agent;
in
{
  options.custom.services.observability.beszel.agent = with lib; {
    enable = mkEnableOption "Enable Beszel agent";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface allowed to access agent port.";
    };
  };

  config = mkIf cfg.enable {
    services = {
      beszel.agent = {
        enable = true;
        environment = {
          KEY = ssh.beszel;
          HUB_URL = "https://beszel.${domain}";
        };
      };
    };

    networking.firewall =
      if cfg.interface != null then
        {
          interfaces."${cfg.interface}".allowedTCPPorts = [ ports.beszel.agent ];
        }
      else
        {
          allowedTCPPorts = [ ports.beszel.agent ];
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
