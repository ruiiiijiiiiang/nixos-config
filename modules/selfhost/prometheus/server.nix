{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.selfhost.prometheus.server;
  prometheus-fqdn = "${subdomains.${config.networking.hostName}.prometheus}.${domains.home}";
  grafana-fqdn = "${subdomains.${config.networking.hostName}.grafana}.${domains.home}";
in
{
  config = mkIf cfg.enable {
    services = {
      prometheus = {
        enable = true;
        port = ports.prometheus.server;
        scrapeConfigs = [
          {
            job_name = "node-exporter";
            static_configs = [
              {
                targets = [ "${addresses.localhost}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-monitor";
                };
              }
              {
                targets = [ "${addresses.home.hosts.pi}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "pi";
                };
              }
              {
                targets = [ "${addresses.home.hosts.vm-network}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-network";
                };
              }
              {
                targets = [ "${addresses.home.hosts.vm-app}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-app";
                };
              }
            ];
          }
          {
            job_name = "nginx-exporter";
            static_configs = [
              {
                targets = [ "${addresses.localhost}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-monitor";
                };
              }
              {
                targets = [ "${addresses.home.hosts.pi}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "pi";
                };
              }
              {
                targets = [ "${addresses.home.hosts.vm-network}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-network";
                };
              }
              {
                targets = [ "${addresses.home.hosts.vm-app}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-app";
                };
              }
            ];
          }
          {
            job_name = "podman-exporter";
            static_configs = [
              {
                targets = [ "${addresses.localhost}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-monitor";
                };
              }
              {
                targets = [ "${addresses.home.hosts.pi}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "pi";
                };
              }
              {
                targets = [ "${addresses.home.hosts.vm-app}:${toString ports.prometheus.exporters.node}" ];
                labels = {
                  instance = "vm-app";
                };
              }
            ];
          }
        ];
      };

      grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = addresses.any;
            http_port = ports.grafana;
            domain = addresses.localhost;
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
        "${prometheus-fqdn}" = {
          useACMEHost = prometheus-fqdn;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${addresses.localhost}:${toString ports.prometheus.server}";
          };
        };

        "${grafana-fqdn}" = {
          useACMEHost = grafana-fqdn;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${addresses.localhost}:${toString ports.grafana}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
