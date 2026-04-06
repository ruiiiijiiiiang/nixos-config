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
    crowdsec.enable = mkEnableOption "Enable Prometheus CrowdSec exporter";
    kea.enable = mkEnableOption "Enable Prometheus Kea exporter";
    libvirt.enable = mkEnableOption "Enable Prometheus Libvirt exporter";
    nginx.enable = mkEnableOption "Enable Prometheus Nginx exporter";
    node.enable = mkEnableOption "Enable Prometheus Node exporter";
    podman.enable = mkEnableOption "Enable Prometheus Podman exporter";
    restic.enable = mkEnableOption "Enable Prometheus Restic exporter";
    wireguard.enable = mkEnableOption "Enable Prometheus WireGuard exporter";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface allowed to access exporter ports.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.interface == null || cfg.interface != "";
        message = "Prometheus exporters interface must not be empty when set.";
      }
      {
        assertion = (!cfg.kea.enable) || config.custom.services.networking.router.enable;
        message = "Prometheus Kea exporter requires networking.router.enable.";
      }
      {
        assertion = (!cfg.libvirt.enable) || config.custom.services.infra.hypervisor.enable;
        message = "Prometheus Libvirt exporter requires infra.hypervisor.enable.";
      }
      {
        assertion = (!cfg.nginx.enable) || config.custom.services.networking.nginx.enable;
        message = "Prometheus Nginx exporter requires networking.nginx.enable.";
      }
      {
        assertion = (!cfg.podman.enable) || config.custom.services.infra.podman.enable;
        message = "Prometheus Podman exporter requires infra.podman.enable.";
      }
      {
        assertion = (!cfg.restic.enable) || config.custom.services.infra.restic.enable;
        message = "Prometheus Restic exporter requires infra.restic.enable.";
      }
      {
        assertion = (!cfg.wireguard.enable) || config.custom.services.networking.wireguard.server.enable;
        message = "Prometheus WireGuard exporter requires networking.wireguard.server.enable.";
      }
    ];

    services = {
      prometheus.exporters = {
        kea = lib.mkIf cfg.kea.enable {
          enable = true;
          port = ports.prometheus.exporters.kea;
          targets = [ "http://${addresses.localhost}:${toString ports.kea.ctrl-agent}" ];
        };

        libvirt = lib.mkIf cfg.libvirt.enable {
          enable = true;
          port = ports.prometheus.exporters.libvirt;
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

        restic = lib.mkIf cfg.restic.enable {
          enable = true;
          port = ports.prometheus.exporters.restic;
          inherit (config.services.restic.backups."data-local") repository passwordFile;
          refreshInterval = 7200;
          user = "root";
        };

        wireguard = lib.mkIf cfg.wireguard.enable {
          enable = true;
          port = ports.prometheus.exporters.wireguard;
        };
      };

      crowdsec.settings.general.prometheus = lib.mkIf cfg.crowdsec.enable {
        enabled = true;
        listen_addr = addresses.localhost;
        listen_port = toString ports.prometheus.exporters.crowdsec;
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
      with lib;
      let
        exporterPorts =
          (optional cfg.crowdsec.enable ports.prometheus.exporters.crowdsec)
          ++ (optional cfg.kea.enable ports.prometheus.exporters.kea)
          ++ (optional cfg.libvirt.enable ports.prometheus.exporters.libvirt)
          ++ (optional cfg.nginx.enable ports.prometheus.exporters.nginx)
          ++ (optional cfg.node.enable ports.prometheus.exporters.node)
          ++ (optional cfg.podman.enable ports.prometheus.exporters.podman)
          ++ (optional cfg.restic.enable ports.prometheus.exporters.restic)
          ++ (optional cfg.wireguard.enable ports.prometheus.exporters.wireguard);
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
