{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports;
  cfg = config.custom.services.observability.dockhand.agent;
in
{
  options.custom.services.observability.dockhand.agent = with lib; {
    enable = mkEnableOption "Hawser container agent";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      dockhand-agent-crt.file = ../../../../secrets/dockhand/agent-crt.age;
      dockhand-agent-key.file = ../../../../secrets/dockhand/agent-key.age;
    };

    virtualisation.oci-containers.containers = {
      dockhand-agent = {
        image = "ghcr.io/finsys/hawser:latest";
        autoStart = true;
        ports = [
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.dockhand.agent}:${toString ports.dockhand.agent}"
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
        extraOptions = [
          "--health-cmd=wget -q --spider --no-check-certificate https://localhost:${toString ports.dockhand.agent}/_hawser/health || exit 1"
        ];
      };
    };
  };
}
