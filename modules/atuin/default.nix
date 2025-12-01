{ config, pkgs, lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  cfg = config.rui.atuin;
in with consts; {
  config = mkIf cfg.enable {
    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_14;
        ensureDatabases = [ "atuin" ];
        ensureUsers = [
          {
            name = "atuin";
            ensureDBOwnership = true;
          }
        ];
      };

      atuin = {
        enable = true;
        openFirewall = false;
        port = ports.atuin;
        host = addresses.localhost;
        maxHistoryLength = 100000;
        openRegistration = false;
        database = {
            createLocally = true;
            uri = "postgresql:///atuin?host=/run/postgresql";
        };
      };

      nginx.virtualHosts."atuin.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.atuin}";
        };
      };
    };
  };
}
