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
    ;
  inherit (helpers) mkVirtualHost;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.prometheus.server;
  fqdn = "${subdomains.${config.networking.hostName}.prometheus}.${domain}";
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
          (lib.mapAttrsToList (hostname: _: "${addresses.infra.hosts.${hostname}}:${toString port}"))
        ];
      }
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
        assertion = lib.all (hostname: builtins.hasAttr hostname addresses.infra.hosts) (builtins.attrNames nixosConfigurations);
        message = "Prometheus scrape target generation requires infra addresses for all nixosConfigurations hosts.";
      }
    ];

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
