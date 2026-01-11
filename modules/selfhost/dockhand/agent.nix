{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) ports;
  cfg = config.custom.selfhost.dockhand.agent;
in
{
  options.custom.selfhost.dockhand.agent = with lib; {
    enable = mkEnableOption "Hawser container agent";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      dockhand-agent-crt.file = ../../../secrets/dockhand/agent-crt.age;
      dockhand-agent-key.file = ../../../secrets/dockhand/agent-key.age;
    };

    virtualisation.oci-containers.containers = {
      dockhand-agent = {
        image = "ghcr.io/finsys/hawser:latest";
        ports = [
          "${toString ports.dockhand.agent}:${toString ports.dockhand.agent}"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "${config.age.secrets.dockhand-agent-crt.path}:/certs/server.crt:ro"
          "${config.age.secrets.dockhand-agent-key.path}:/certs/server.key:ro"
        ];
        environment = {
          TLS_CERT = "/certs/server.crt";
          TLS_KEY = "/certs/server.key";
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ ports.dockhand.agent ];
  };
}
