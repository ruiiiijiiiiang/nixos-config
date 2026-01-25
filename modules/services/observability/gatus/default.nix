{
  config,
  consts,
  lib,
  helpers,
  inputs,
  ...
}:
let
  inherit (consts) domains subdomains ports;
  inherit (helpers) mkVirtualHost getEnabledServices;
  cfg = config.custom.services.observability.gatus;
  fqdn = "${subdomains.${config.networking.hostName}.gatus}.${domains.home}";

  mkGatusEndpoints =
    { inputs, hostName }:
    let
      inherit (inputs.self.nixosConfigurations.${hostName}) config;
      enabledServices = getEnabledServices { inherit config; };
    in
    lib.mapAttrsToList (service: subdomain: {
      name = service;
      url = "https://${subdomain}.${domains.home}";
      group = hostName;
      interval = "1m";
      conditions = [ "[STATUS] == 200" ];
    }) enabledServices;

  endpoints = lib.concatMap (
    hostName:
    mkGatusEndpoints {
      inherit inputs hostName;
    }
  ) (builtins.attrNames inputs.self.nixosConfigurations);
in
{
  options.custom.services.observability.gatus = with lib; {
    enable = mkEnableOption "Gatus monitoring dashboard";
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
