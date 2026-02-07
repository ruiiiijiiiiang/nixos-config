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
  cfg = config.custom.services.apps.tools.portainer;
  fqdn = "${subdomains.${config.networking.hostName}.portainer}.${domains.home}";
in
{
  options.custom.services.apps.tools.portainer = with lib; {
    enable = mkEnableOption "Portainer container management";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      portainer = {
        image = "docker.io/portainer/portainer-ce";
        ports = [
          "${addresses.localhost}:${toString ports.portainer.server}:${toString ports.portainer.server}"
          "${addresses.localhost}:${toString ports.portainer.edge}:${toString ports.portainer.edge}"
        ];
        volumes = [
          "/run/docker.sock:/var/run/docker.sock:ro"
          "portainer_data:/data"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.portainer.server;
    };
  };
}
