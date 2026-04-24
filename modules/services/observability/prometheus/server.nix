{
  config,
  consts,
  inputs,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    endpoints
    ;
  inherit (helpers)
    getHostAddress
    mkVirtualHost
    ;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.prometheus.server;
  fqdn = "${subdomains.${config.networking.hostName}.prometheus}.${domain}";
  monitoredExporters = {
    inherit (ports.prometheus.exporters)
      # crowdsec
      kea
      libvirt
      nginx
      node
      podman
      restic
      wireguard
      ;
  };

  mkScrapeJob = exporterName: port: {
    job_name = "${exporterName}-exporter";
    scrape_interval = "30s";
    static_configs = lib.pipe nixosConfigurations [
      (lib.filterAttrs (
        _: hostConfig:
        hostConfig.config.custom.services.observability.prometheus.exporters.${exporterName}.enable or false
      ))
      (lib.mapAttrsToList (
        hostname: _: {
          targets = [ "${getHostAddress hostname}:${toString port}" ];
          labels.hostname = hostname;
        }
      ))
    ];
  };
in
{
  options.custom.services.observability.prometheus.server = with lib; {
    enable = mkEnableOption "Enable Prometheus server";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.services.observability.ntfy.enable;
        message = "Prometheus alerting requires custom.services.observability.ntfy.enable";
      }
    ];

    services = {
      prometheus = {
        enable = true;
        port = ports.prometheus.server;
        alertmanagers = [
          {
            scheme = "http";
            static_configs = [
              {
                targets = [ "${addresses.localhost}:${toString config.services.prometheus.alertmanager.port}" ];
              }
            ];
          }
        ];
        rules = [
          ''
            groups:
              - name: system
                rules:
                  - alert: HostDown
                    expr: up{job="node-exporter"} == 0
                    for: 5m
                    labels:
                      severity: critical
                    annotations:
                      summary: "Host down: {{ $labels.hostname }}"
                      description: "Prometheus has not scraped node_exporter on {{ $labels.hostname }} for 5 minutes."

                  - alert: HostLowDiskSpace
                    expr: |
                      (
                        node_filesystem_avail_bytes{job="node-exporter", mountpoint="/", fstype!~"tmpfs|overlay|squashfs"}
                        /
                        node_filesystem_size_bytes{job="node-exporter", mountpoint="/", fstype!~"tmpfs|overlay|squashfs"}
                      ) * 100 < 10
                    for: 5m
                    labels:
                      severity: warning
                    annotations:
                      summary: "Low disk space: {{ $labels.hostname }}"
                      description: "Root filesystem free space is below 10% on {{ $labels.hostname }}."

                  - alert: HostLowMemory
                    expr: |
                      (
                        node_memory_MemAvailable_bytes{job="node-exporter"}
                        /
                        node_memory_MemTotal_bytes{job="node-exporter"}
                      ) * 100 < 10
                    for: 5m
                    labels:
                      severity: warning
                    annotations:
                      summary: "Low memory: {{ $labels.hostname }}"
                      description: "Available memory is below 10% on {{ $labels.hostname }}."
          ''
        ];
        scrapeConfigs = lib.mapAttrsToList mkScrapeJob monitoredExporters;

        alertmanager = {
          enable = true;
          configuration = {
            global.resolve_timeout = "5m";

            route = {
              receiver = "ntfy";
              group_by = [
                "alertname"
                "hostname"
              ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "6h";
            };

            receivers = [
              {
                name = "ntfy";
                webhook_configs = [
                  {
                    url = "http://${addresses.localhost}:${toString ports.prometheus.alertmanager}/hook";
                    send_resolved = true;
                    max_alerts = 0;
                  }
                ];
              }
            ];
          };
        };

        alertmanager-ntfy = {
          enable = true;
          settings = {
            http.addr = "${addresses.localhost}:${toString ports.prometheus.alertmanager}";
            ntfy = {
              baseurl = "https://${endpoints.ntfy-server}";
              notification = {
                topic = "prometheus-alerts";
                priority = ''status == "firing" ? "high" : "default"'';
                templates = {
                  title = ''{{ if eq .Status "resolved" }}Resolved: {{ end }}{{ index .Annotations "summary" }}'';
                  description = ''{{ index .Annotations "description" }}'';
                };
              };
            };
          };
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.prometheus.server;
      };
    };
  };
}
