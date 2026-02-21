{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports;
  cfg = config.custom.services.observability.loki.server;
in
{
  options.custom.services.observability.loki.server = with lib; {
    enable = mkEnableOption "Loki log aggregation system";
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = ports.loki.server;
        };

        common = {
          ring = {
            instance_addr = addresses.any;
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };

        schema_config = {
          configs = [
            {
              from = "2025-11-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ ports.loki.server ];
  };
}
