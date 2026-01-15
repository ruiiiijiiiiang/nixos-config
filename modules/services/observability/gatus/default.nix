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
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.gatus;
  fqdn = "${subdomains.${config.networking.hostName}.gatus}.${domains.home}";

  endpoints =
    helpers.mkGatusEndpoints {
      inherit inputs;
      hostName = "pi";
    }
    ++ helpers.mkGatusEndpoints {
      inherit inputs;
      hostName = "vm-network";
    }
    ++ helpers.mkGatusEndpoints {
      inherit inputs;
      hostName = "vm-app";
    }
    ++ helpers.mkGatusEndpoints {
      inherit inputs;
      hostName = "vm-monitor";
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
