{
  config,
  consts,
  lib,
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
  cfg = config.custom.selfhost.portainer;
  fqdn = "${subdomains.${config.networking.hostName}.portainer}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      portainer = {
        image = "portainer/portainer-ce";
        ports = [
          "${addresses.localhost}:${toString ports.portainer.server}:${toString ports.portainer.server}"
          "${addresses.localhost}:${toString ports.portainer.edge}:${toString ports.portainer.edge}"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "portainer_data:/data"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "L+ /var/run/docker.sock - - - - /run/podman/podman.sock"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.portainer.server;
      proxyWebsockets = true;
    };
  };
}
