{
  config,
  lib,
  consts,
  ...
}:
let
  inherit (consts) ports;
  cfg = config.selfhost.dockhand.agent;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      dockhand-agent = {
        image = "ghcr.io/finsys/hawser:latest";
        ports = [
          "${toString ports.dockhand.agent}:${toString ports.dockhand.agent}"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        extraOptions = [ "--pull=always" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ ports.dockhand.agent ];
  };
}
