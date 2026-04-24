{
  config,
  consts,
  lib,
  helpers,
  inputs,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost getEnabledServices;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.observability.gatus;
  fqdn = "${subdomains.${config.networking.hostName}.gatus}.${domain}";

  interval = "1m";
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

  endpoints = lib.concatMap (
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
          web.port = ports.gatus;
          alerting.ntfy = {
            url = "http://${addresses.localhost}:${toString ports.ntfy}";
            topic = "gatus-alerts";
            priority = 4;
            click = "https://${fqdn}";
            "default-alert" = {
              description = "Endpoint offline for more than 5 minutes";
              "failure-threshold" = 6;
              "success-threshold" = 2;
              "send-on-resolved" = true;
            };
          };
          inherit endpoints;
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.gatus;
      };
    };

    assertions = [
      {
        assertion = config.custom.services.observability.ntfy.enable;
        message = "Gatus ntfy alerting requires observability.ntfy to be enabled on the same host.";
      }
    ];
  };
}
