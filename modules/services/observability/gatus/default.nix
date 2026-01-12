{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts) domains subdomains ports;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.gatus;
  fqdn = "${subdomains.${config.networking.hostName}.gatus}.${domains.home}";

  mkEndpoints =
    {
      host,
      services,
      disabledServices ? [ ],
    }:
    let
      pathOverrides = {
        stirlingpdf = "/login";
        yourls = "/admin";
      };
      activeServices = lib.filterAttrs (name: _: !(builtins.elem name disabledServices)) services;
    in
    lib.mapAttrsToList (service: subdomain: {
      name = service;
      url = "https://${subdomain}.${domains.home}${pathOverrides.${service} or ""}";
      group = host;
      interval = "1m";
      conditions = [ "[STATUS] == 200" ];
    }) activeServices;

  endpoints =
    mkEndpoints {
      host = "pi";
      services = subdomains.pi;
    }
    ++ mkEndpoints {
      host = "vm-network";
      services = subdomains.vm-network;
    }
    ++ mkEndpoints {
      host = "vm-app";
      services = subdomains.vm-app;
      disabledServices = [
        "bentopdf"
        "nextcloud"
        "portainer"
      ];
    }
    ++ mkEndpoints {
      host = "vm-monitor";
      services = subdomains.vm-monitor;
    };
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
