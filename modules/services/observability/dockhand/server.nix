{
  config,
  consts,
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
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.dockhand.server;
  fqdn = "${subdomains.${config.networking.hostName}.dockhand}.${domains.home}";
in
{
  options.custom.services.observability.dockhand.server = with lib; {
    enable = mkEnableOption "Dockhand container management";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      dockhand-server = {
        image = "docker.io/fnsys/dockhand:latest";
        ports = [ "${addresses.localhost}:${toString ports.dockhand.server}:3000" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "dockhand_data:/app/data"
        ];
        environment = {
          NODE_TLS_REJECT_UNAUTHORIZED = "0";
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.dockhand.server;
    };
  };
}
