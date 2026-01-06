{
  config,
  lib,
  consts,
  utilFns,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.selfhost.dockhand.server;
  fqdn = "${subdomains.${config.networking.hostName}.dockhand}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      dockhand-server = {
        image = "fnsys/dockhand:latest";
        ports = [ "${addresses.localhost}:${toString ports.dockhand.server}:3000" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "dockhand_data:/app/data"
        ];
        extraOptions = [ "--pull=always" ];
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.dockhand.server;
      proxyWebsockets = true;
    };
  };
}
