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
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost getHostAddress;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.prometheus.server;
  fqdn = "${subdomains.${config.networking.hostName}.prometheus}.${domains.home}";
  monitoredExporters = {
    inherit (ports.prometheus.exporters)
      # crowdsec
      kea
      nginx
      node
      podman
      wireguard
      ;
  };

  mkScrapeJob = exporterName: port: {
    job_name = "${exporterName}-exporter";
    scrape_interval = "30s";
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

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.prometheus.server;
      };
    };
  };
}
