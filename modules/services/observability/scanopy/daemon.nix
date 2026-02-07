{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports oci-uids;
  cfg = config.custom.services.observability.scanopy.daemon;
in
{
  options.custom.services.observability.scanopy.daemon = with lib; {
    enable = mkEnableOption "Scanopy daemon";
    envFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to Scanopy daemon environment file";
      # SCANOPY_DAEMON_API_KEY
      # SCANOPY_NETWORK_ID
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.envFile != null;
        message = "Scanopy daemon is enabled but environment file is missing.";
      }
    ];

    virtualisation.oci-containers.containers = {
      scanopy-daemon = {
        image = "ghcr.io/scanopy/scanopy/daemon:latest";
        user = "${toString oci-uids.nobody}:${toString oci-uids.podman}";
        volumes = [
          "scanopy-daemon-config:/tmp/.config/daemon:U"
          "/run/docker.sock:/var/run/docker.sock:ro"
        ];
        environmentFiles = [ cfg.envFile ];
        environment = {
          HOME = "/tmp";
          SCANOPY_SERVER_URL = "http://${addresses.infra.hosts.vm-monitor}:${toString ports.scanopy.server}";
          SCANOPY_NAME = "${config.networking.hostName}-daemon";
          SCANOPY_MODE = "Pull";
          SCANOPY_CONCURRENT_SCANS = "10";
        };
        networks = [ "host" ];
        extraOptions = [
          "--cap-add=NET_RAW"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };
  };
}
