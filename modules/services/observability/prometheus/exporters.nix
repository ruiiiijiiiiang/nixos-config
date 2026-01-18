{ config, lib, ... }:
let
  inherit (import ../../../../lib/consts.nix) addresses ports;
  cfg = config.custom.services.observability.prometheus.exporters;
in
{
  options.custom.services.observability.prometheus.exporters = with lib; {
    nginx.enable = mkEnableOption "Prometheus Nginx exporter";
    node.enable = mkEnableOption "Prometheus Node exporter";
    podman.enable = mkEnableOption "Prometheus Podman exporter";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface to open ports";
    };
  };

  config = {
    services.prometheus.exporters = {
      nginx = lib.mkIf cfg.nginx.enable {
        enable = true;
        port = ports.prometheus.exporters.nginx;
        scrapeUri = "http://${addresses.localhost}:${toString ports.nginx.stub}/stub_status";
      };

      node = lib.mkIf cfg.node.enable {
        enable = true;
        port = ports.prometheus.exporters.node;
        enabledCollectors = [
          "systemd"
          "processes"
          "tcpstat"
        ];
      };
    };

    virtualisation.oci-containers.containers.podman-exporter = lib.mkIf cfg.podman.enable {
      image = "quay.io/navidys/prometheus-podman-exporter:latest";
      ports = [
        "${
          addresses.home.hosts.${config.networking.hostName}
        }:${toString ports.prometheus.exporters.podman}:${toString ports.prometheus.exporters.podman}"
      ];
      volumes = [
        "/run/podman/podman.sock:/run/podman/podman.sock"
      ];
      environment = {
        CONTAINER_HOST = "unix:///run/podman/podman.sock";
      };
      user = "root";
      extraOptions = [ "--security-opt=label=disable" ];
    };

    networking.firewall =
      let
        exporterPorts =
          (lib.optional cfg.nginx.enable ports.prometheus.exporters.nginx)
          ++ (lib.optional cfg.node.enable ports.prometheus.exporters.node)
          ++ (lib.optional cfg.podman.enable ports.prometheus.exporters.podman);
      in
      if cfg.interface != null then
        {
          interfaces."${cfg.interface}".allowedTCPPorts = exporterPorts;
        }
      else
        {
          allowedTCPPorts = exporterPorts;
        };
  };
}
