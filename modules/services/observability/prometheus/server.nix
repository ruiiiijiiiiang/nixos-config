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
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost getHostAddress;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.prometheus.server;
  prometheus-fqdn = "${subdomains.${config.networking.hostName}.prometheus}.${domains.home}";
  grafana-fqdn = "${subdomains.${config.networking.hostName}.grafana}.${domains.home}";
  monitoredExporters = {
    inherit (ports.prometheus.exporters)
      kea
      nginx
      node
      podman
      ;
  };

  mkScrapeJob = exporterName: port: {
    job_name = "${exporterName}-exporter";
    static_configs = [
      {
        targets = lib.pipe nixosConfigurations [
          (lib.filterAttrs (
            _: hostConfig:
            hostConfig.config.custom.services.observability.prometheus.exporters.${exporterName}.enable or false
          ))
          (lib.mapAttrsToList (
            hostname: _: "${getHostAddress { inherit config hostname; }}:${toString port}"
          ))
        ];
      }
    ];
  };
in
{
  options.custom.services.observability.prometheus.server = with lib; {
    enable = mkEnableOption "Prometheus metrics server";
  };

  config = lib.mkIf cfg.enable {
    services = {
      prometheus = {
        enable = true;
        port = ports.prometheus.server;
        scrapeConfigs = lib.mapAttrsToList mkScrapeJob monitoredExporters;
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
