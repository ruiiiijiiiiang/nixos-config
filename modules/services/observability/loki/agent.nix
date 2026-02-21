{ config, consts, lib, ... }:
let
  inherit (consts) addresses ports;
  cfg = config.custom.services.observability.loki.agent;
in
{
  options.custom.services.observability.loki.agent = with lib; {
    enable = mkEnableOption "Promtail log collection agent for Loki";
    serverAddress = mkOption {
      type = types.str;
      default = addresses.localhost;
      description = "Address of the Loki server";
    };
  };

  config = lib.mkIf cfg.enable {
    services.promtail = {
      enable = true;

      configuration = {
        server = {
          http_listen_port = ports.loki.agent;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [{
          url = "http://${cfg.serverAddress}:${toString ports.loki.server}/loki/api/v1/push";
        }];

        scrape_configs = [{
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }];
      };
    };

    systemd.services.promtail.serviceConfig.SupplementaryGroups = [ "systemd-journal" ];
  };
}
