{ config, consts, lib, ... }:
let
  inherit (consts) addresses ports;
  cfg = config.custom.services.observability.loki.agent;
in
{
  options.custom.services.observability.loki.agent = with lib; {
    enable = mkEnableOption "Enable Loki log agent";
    serverAddress = mkOption {
      type = types.str;
      default = addresses.localhost;
      description = "Loki server address.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.serverAddress != "";
        message = "Loki agent serverAddress must not be empty.";
      }
    ];

    services.alloy = {
      enable = true;
    };

    environment.etc."alloy/loki-journal.alloy".text = ''
      loki.write "nixos_loki_remote" {
        endpoint {
          url = "http://${cfg.serverAddress}:${toString ports.loki.server}/loki/api/v1/push"
        }
      }

      loki.relabel "nixos_journal_labels" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }

        rule {
          source_labels = ["__journal__systemd_unit"]
          regex         = ".*"
          replacement   = "systemd-journal"
          target_label  = "job"
        }

        rule {
          source_labels = ["__journal__systemd_unit"]
          regex         = ".*"
          replacement   = "${config.networking.hostName}"
          target_label  = "host"
        }
      }

      loki.source.journal "nixos_journal" {
        forward_to    = [loki.write.nixos_loki_remote.receiver]
        relabel_rules = loki.relabel.nixos_journal_labels.rules
        max_age       = "12h"
      }
    '';
  };
}
