{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.portainer;
  fqdn = "${consts.subdomains.${config.networking.hostName}.portainer}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      portainer = {
        image = "portainer/portainer-ce";
        ports = [
          "${toString ports.portainer.server}:${toString ports.portainer.server}"
          "${toString ports.portainer.edge}:${toString ports.portainer.edge}"
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
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };
}
