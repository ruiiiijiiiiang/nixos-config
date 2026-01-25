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
  cfg = config.custom.services.observability.myspeed;
  fqdn = "${subdomains.${config.networking.hostName}.myspeed}.${domains.home}";
in
{
  options.custom.services.observability.myspeed = with lib; {
    enable = mkEnableOption "Speed test analysis";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.myspeed = {
      image = "docker.io/germannewsmaker/myspeed:latest";
      ports = [ "${toString ports.myspeed}:${toString ports.myspeed}" ];
      volumes = [ "myspeed:/myspeed/data" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.myspeed;
    };
  };
}
