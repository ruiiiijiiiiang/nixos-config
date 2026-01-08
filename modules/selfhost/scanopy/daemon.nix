{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses ports;
  cfg = config.custom.selfhost.scanopy.daemon;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      scanopy-daemon-env.file = ../../../secrets/scanopy/daemon-env.age;
    };

    virtualisation.oci-containers.containers = {
      scanopy-daemon = {
        image = "ghcr.io/scanopy/scanopy/daemon:latest";
        volumes = [
          "scanopy-daemon-config:/root/.config/daemon"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        environmentFiles = [ config.age.secrets.scanopy-daemon-env.path ];
        environment = {
          SCANOPY_SERVER_URL = "http://${addresses.home.hosts.vm-monitor}:${toString ports.scanopy.server}";
          SCANOPY_NAME = "${config.networking.hostName}-daemon";
          SCANOPY_MODE = "Pull";
        };
        networks = [ "host" ];
        privileged = true;
        extraOptions = [ "--pull=always" ];
      };
    };
  };
}
