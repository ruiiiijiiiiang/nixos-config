{
  secretsDir,
  config,
  consts,
  helpers,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost ensureFile;
  cfg = config.custom.services.apps.web.searxng;
  fqdn = "${subdomains.${config.networking.hostName}.searxng}.${domain}";

  settingsFile = pkgs.writeText "searxng-settings.yml" /* yaml */ ''
    use_default_settings: true
    search:
      formats:
        - html
        - json
  '';
in
{
  options.custom.services.apps.web.searxng = {
    enable = lib.mkEnableOption "Enable SearXNG";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      searxng-env.file = secretsDir + "/apps/searxng/env.age";
      # SEARXNG_SECRET
    };

    virtualisation.oci-containers.containers = {
      searxng = {
        image = "docker.io/searxng/searxng:latest";
        user = "${toString oci-uids.searxng}:${toString oci-uids.searxng}";
        ports = [ "${addresses.localhost}:${toString ports.searxng}:8080" ];
        volumes = [
          "/var/lib/searxng/config/:/etc/searxng/"
          "/var/lib/searxng/data/:/var/cache/searxng/"
        ];
        environmentFiles = [ config.age.secrets.searxng-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/searxng/config 0700 ${toString oci-uids.searxng} ${toString oci-uids.searxng} - -"
        "d /var/lib/searxng/data 0700 ${toString oci-uids.searxng} ${toString oci-uids.searxng} - -"
      ];

      services.podman-searxng = {
        preStart = lib.mkAfter ''
          ${ensureFile {
            source = settingsFile;
            destination = "/var/lib/searxng/config/settings.yml";
            user = toString oci-uids.searxng;
            group = toString oci-uids.searxng;
            mode = "0600";
          }}
        '';
      };
    };

    users = mkOciUser "searxng";

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.searxng;
      };
    };
  };
}
