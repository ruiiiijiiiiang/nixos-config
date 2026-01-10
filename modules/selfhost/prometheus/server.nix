{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.selfhost.prometheus.server;
  prometheus-fqdn = "${subdomains.${config.networking.hostName}.prometheus}.${domains.home}";
  grafana-fqdn = "${subdomains.${config.networking.hostName}.grafana}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    services = {
      prometheus = {
        enable = true;
        port = ports.prometheus.server;
        scrapeConfigs = [
          {
            job_name = "node-exporter";
            static_configs = [
              {
                targets = [
                  "${addresses.localhost}:${toString ports.prometheus.exporters.node}"
                  "${addresses.home.hosts.pi}:${toString ports.prometheus.exporters.node}"
                  "${addresses.home.hosts.vm-network}:${toString ports.prometheus.exporters.node}"
                  "${addresses.home.hosts.vm-app}:${toString ports.prometheus.exporters.node}"
                ];
              }
            ];
          }
          {
            job_name = "nginx-exporter";
            static_configs = [
              {
                targets = [
                  "${addresses.localhost}:${toString ports.prometheus.exporters.nginx}"
                  "${addresses.home.hosts.pi}:${toString ports.prometheus.exporters.nginx}"
                  "${addresses.home.hosts.vm-network}:${toString ports.prometheus.exporters.nginx}"
                  "${addresses.home.hosts.vm-app}:${toString ports.prometheus.exporters.nginx}"
                ];
              }
            ];
          }
          {
            job_name = "podman-exporter";
            static_configs = [
              {
                targets = [
                  "${addresses.home.hosts.pi}:${toString ports.prometheus.exporters.podman}"
                  "${addresses.home.hosts.vm-app}:${toString ports.prometheus.exporters.podman}"
                  "${addresses.home.hosts.vm-monitor}:${toString ports.prometheus.exporters.podman}"
                ];
              }
            ];
          }
        ];
      };

      grafana = {
        enable = true;
        settings = {
          server = {
            root_url = "https://${grafana-fqdn}";
            http_addr = addresses.any;
            http_port = ports.grafana;
            domain = addresses.localhost;
          };
          auth = {
            oauth_allow_insecure_email_lookup = true;
          };
        };

        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://${addresses.localhost}:${toString ports.prometheus.server}";
            }
          ];
        };
      };

      nginx.virtualHosts = {
        "${prometheus-fqdn}" = mkVirtualHost {
          fqdn = prometheus-fqdn;
          port = ports.prometheus.server;
        };

        "${grafana-fqdn}" = mkVirtualHost {
          fqdn = grafana-fqdn;
          port = ports.grafana;
        };
      };
    };
  };
}
