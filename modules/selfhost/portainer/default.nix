{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (import ../../../lib/consts.nix)
    addresses
    domains
    subdomains
    ports
    ;
  cfg = config.selfhost.portainer;
  fqdn = "${subdomains.${config.networking.hostName}.portainer}.${domains.home}";
in
{
  config = mkIf cfg.enable {
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
      };
    };

    systemd.tmpfiles.rules = [
      "L+ /var/run/docker.sock - - - - /run/podman/podman.sock"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.portainer.server}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
