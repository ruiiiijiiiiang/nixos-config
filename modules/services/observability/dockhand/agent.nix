{
  secretsDir,
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts) ports oci-uids;
  inherit (helpers) getHostAddress;
  cfg = config.custom.services.observability.dockhand.agent;
in
{
  options.custom.services.observability.dockhand.agent = with lib; {
    enable = mkEnableOption "Enable Dockhand agent";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface allowed to access agent port.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.interface == null || cfg.interface != "";
        message = "Dockhand agent interface must not be empty when set.";
      }
    ];

    age.secrets = {
      dockhand-agent-crt = {
        file = secretsDir + "/observability/dockhand/agent-crt.age";
        owner = toString oci-uids.dockhand;
        group = toString oci-uids.dockhand;
        mode = "400";
      };
      dockhand-agent-key = {
        file = secretsDir + "/observability/dockhand/agent-key.age";
        owner = toString oci-uids.dockhand;
        group = toString oci-uids.dockhand;
        mode = "400";
      };
    };

    virtualisation.oci-containers.containers = {
      dockhand-agent = {
        image = "ghcr.io/finsys/hawser:latest";
        user = "${toString oci-uids.dockhand}:${toString oci-uids.dockhand}";
        ports = [
          "${getHostAddress config.networking.hostName}:${toString ports.dockhand.agent}:${toString ports.dockhand.agent}"
          "[${
            getHostAddress {
              hostName = config.networking.hostName;
              isV6 = true;
            }
          }]:${toString ports.dockhand.agent}:${toString ports.dockhand.agent}"
        ];
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${config.age.secrets.dockhand-agent-crt.path}:/certs/server.crt:ro"
          "${config.age.secrets.dockhand-agent-key.path}:/certs/server.key:ro"
        ];
        environment = {
          TLS_CERT = "/certs/server.crt";
          TLS_KEY = "/certs/server.key";
          AGENT_NAME = config.networking.hostName;
          ALLOW_INSECURE_NO_AUTH = "true";
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        extraOptions = [ "--group-add=${toString oci-uids.podman}" ];
      };
    };

    networking.firewall =
      if cfg.interface != null then
        {
          interfaces."${cfg.interface}".allowedTCPPorts = [ ports.dockhand.agent ];
        }
      else
        {
          allowedTCPPorts = [ ports.dockhand.agent ];
        };
  };
}
