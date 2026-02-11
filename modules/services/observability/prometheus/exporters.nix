{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports oci-uids;
  cfg = config.custom.services.observability.prometheus.exporters;
in
{
  options.custom.services.observability.prometheus.exporters = with lib; {
    kea.enable = mkEnableOption "Prometheus Kea exporter";
    nginx.enable = mkEnableOption "Prometheus Nginx exporter";
    node.enable = mkEnableOption "Prometheus Node exporter";
    podman.enable = mkEnableOption "Prometheus Podman exporter";
    wireguard.enable = mkEnableOption "Prometheus Wireguard exporter";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface to open ports";
    };
  };

  config = {
    services.prometheus.exporters = {
      kea = lib.mkIf cfg.kea.enable {
        enable = true;
        listenAddress = addresses.any;
        port = ports.prometheus.exporters.kea;
        targets = [ "http://${addresses.localhost}:${toString ports.kea.ctrl-agent}" ];
      };

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

      wireguard = lib.mkIf cfg.wireguard.enable {
        enable = true;
        port = ports.prometheus.exporters.wireguard;
      };
    };

    virtualisation.oci-containers.containers.podman-exporter = lib.mkIf cfg.podman.enable {
      image = "quay.io/navidys/prometheus-podman-exporter:latest";
      user = "${toString oci-uids.nobody}:${toString oci-uids.podman}";
      ports = [
        "${
          addresses.infra.hosts.${config.networking.hostName}
        }:${toString ports.prometheus.exporters.podman}:${toString ports.prometheus.exporters.podman}"
      ];
      volumes = [
        "/run/podman/podman.sock:/run/podman/podman.sock:ro"
      ];
      environment = {
        CONTAINER_HOST = "unix:///run/podman/podman.sock";
      };
      extraOptions = [ "--security-opt=label=disable" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    networking.firewall =
      let
        exporterPorts =
          (lib.optional cfg.kea.enable ports.prometheus.exporters.kea)
          ++ (lib.optional cfg.nginx.enable ports.prometheus.exporters.nginx)
          ++ (lib.optional cfg.node.enable ports.prometheus.exporters.node)
          ++ (lib.optional cfg.podman.enable ports.prometheus.exporters.podman)
          ++ (lib.optional cfg.wireguard.enable ports.prometheus.exporters.wireguard);
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
