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
    }) enabledServices;

  manualGatusEndpoints = [
    {
      name = "legacy pihole";
      url = "https://${addresses.infra.hosts.pi-legacy}/admin";
      group = "pi-legacy";
      inherit interval conditions;
    }
  ];

  endpoints = lib.concatMap (
    hostName:
    mkGatusEndpoints {
      inherit inputs hostName;
    }
    ++ manualGatusEndpoints
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
          inherit endpoints;
        };
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.gatus;
      };
    };
  };
}
