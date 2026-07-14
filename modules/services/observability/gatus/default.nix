{
  config,
  consts,
  helpers,
  inputs,
  lib,
  ...
}:
let
  inherit (consts)
    domain
    subdomains
    ports
    endpoints
    ;
  inherit (helpers) mkVirtualHost getEnabledServices;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.gatus;
  fqdn = "${subdomains.${config.networking.hostName}.gatus}.${domain}";
  ntfyEnabled = nixosConfigurations.vm-monitor.config.custom.services.observability.ntfy.enable;

  interval = "10m";
  conditions = [ "[STATUS] == 200" ];
  extraPaths = {
    krawl = "/krawl-honeypot-dashboard";
  };

  mkGatusEndpoints =
    { inputs, hostName }:
    let
      inherit (nixosConfigurations.${hostName}) config;
      enabledServices = getEnabledServices { inherit config; };
    in
    lib.mapAttrsToList (service: subdomain: {
      name = service;
      url = "https://${subdomain}.${domain}${extraPaths.${service} or ""}";
      group = hostName;
      inherit interval conditions;
      alerts = [ { type = "ntfy"; } ];
    }) enabledServices;

  gatusEndpoints = lib.concatMap (
    hostName:
    mkGatusEndpoints {
      inherit inputs hostName;
    }
  ) (lib.attrNames nixosConfigurations);
in
{
  options.custom.services.observability.gatus = with lib; {
    enable = mkEnableOption "Enable Gatus";
  };

  config = lib.mkIf cfg.enable {
    services = {
      gatus = {
        enable = true;
        settings = {
          endpoints = gatusEndpoints;
          web.port = ports.gatus;
          alerting.ntfy = lib.mkIf ntfyEnabled {
            url = "https://${endpoints.ntfy-server}";
            topic = endpoints.ntfy-topics.gatus-alerts;
            priority = 4;
            click = "https://${fqdn}";
          };
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.gatus;
      };
    };
  };
}
