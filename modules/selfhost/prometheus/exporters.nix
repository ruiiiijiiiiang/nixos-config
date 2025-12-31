{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (import ../../../lib/consts.nix) addresses ports;
  cfg = config.selfhost.prometheus.exporters;
in
{
  services.prometheus.exporters = {
    nginx = mkIf cfg.nginx.enable {
      enable = true;
      port = ports.prometheus.exporters.nginx;
      scrapeUri = "http://${addresses.localhost}:${toString ports.nginx.stub}/stub_status";
      openFirewall = true;
    };

    node = mkIf cfg.node.enable {
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

  virtualisation.oci-containers.containers.podman-exporter = mkIf cfg.podman.enable {
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

  networking.firewall.allowedTCPPorts = mkIf cfg.podman.enable [
    ports.prometheus.exporters.podman
  ];
}
