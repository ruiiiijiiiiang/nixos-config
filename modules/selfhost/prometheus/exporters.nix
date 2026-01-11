{ config, lib, ... }:
let
  inherit (import ../../../lib/consts.nix) addresses ports;
  cfg = config.custom.selfhost.prometheus.exporters;
in
{
  options.custom.selfhost.prometheus.exporters = with lib; {
    nginx.enable = mkEnableOption "Prometheus Nginx exporter";
    node.enable = mkEnableOption "Prometheus Node exporter";
    podman.enable = mkEnableOption "Prometheus Podman exporter";
  };

  config = {
    services.prometheus.exporters = {
      nginx = lib.mkIf cfg.nginx.enable {
        enable = true;
        port = ports.prometheus.exporters.nginx;
        scrapeUri = "http://${addresses.localhost}:${toString ports.nginx.stub}/stub_status";
        openFirewall = true;
      };

      node = lib.mkIf cfg.node.enable {
        enable = true;
        port = ports.prometheus.exporters.node;
        openFirewall = true;
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
        "${toString ports.prometheus.exporters.podman}:${toString ports.prometheus.exporters.podman}"
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

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.podman.enable [
      ports.prometheus.exporters.podman
    ];
  };
}