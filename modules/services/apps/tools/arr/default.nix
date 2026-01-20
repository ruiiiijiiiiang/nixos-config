{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    timeZone
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.tools.arr;
  lidarr-fqdn = "${subdomains.${config.networking.hostName}.lidarr}.${domains.home}";
  radarr-fqdn = "${subdomains.${config.networking.hostName}.radarr}.${domains.home}";
  sonarr-fqdn = "${subdomains.${config.networking.hostName}.sonarr}.${domains.home}";
  prowlarr-fqdn = "${subdomains.${config.networking.hostName}.prowlarr}.${domains.home}";
  bazarr-fqdn = "${subdomains.${config.networking.hostName}.bazarr}.${domains.home}";
  commonEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = timeZone;
  };
in
{
  options.custom.services.apps.tools.arr = with lib; {
    enable = mkEnableOption "Arr stack";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        autoStart = true;
        ports = [
          "${addresses.localhost}:${toString ports.lidarr}:${toString ports.lidarr}"
          "${addresses.home.hosts.${config.networking.hostName}}:${toString ports.lidarr}:${toString ports.lidarr}"
        ];
        environment = commonEnv;
        volumes = [
          "/var/lib/lidarr/config:/config"
          "/media:/mnt"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        autoStart = true;
        ports = [
          "${addresses.localhost}:${toString ports.radarr}:${toString ports.radarr}"
          "${addresses.home.hosts.${config.networking.hostName}}:${toString ports.radarr}:${toString ports.radarr}"
        ];
        environment = commonEnv;
        volumes = [
          "/var/lib/radarr/config:/config"
          "/media:/mnt"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        autoStart = true;
        ports = [
          "${addresses.localhost}:${toString ports.sonarr}:${toString ports.sonarr}"
          "${addresses.home.hosts.${config.networking.hostName}}:${toString ports.sonarr}:${toString ports.sonarr}"
        ];
        environment = commonEnv;
        volumes = [
          "/var/lib/sonarr/config:/config"
          "/media:/mnt"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        ports = [
          "${addresses.localhost}:${toString ports.prowlarr}:${toString ports.prowlarr}"
          "${addresses.home.hosts.${config.networking.hostName}}:${toString ports.prowlarr}:${toString ports.prowlarr}"
        ];
        environment = commonEnv;
        volumes = [
          "/var/lib/prowlarr/config:/config"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        autoStart = true;
        ports = [ "${toString ports.bazarr}:${toString ports.bazarr}" ];
        environment = commonEnv;
        volumes = [
          "/var/lib/bazarr/config:/config"
          "/media:/mnt"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      flaresolverr = {
        image = "docker.io/flaresolverr/flaresolverr:latest";
        autoStart = true;
        dependsOn = [ "prowlarr" ];
        ports = [ "${toString ports.flaresolverr}:${toString ports.flaresolverr}" ];
        environment = {
          LOG_LEVEL = "info";
          TZ = timeZone;
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/lidarr/config 0755 1000 1000 - -"
      "d /media/music 0775 1000 1000 - -"

      "d /var/lib/radarr/config 0755 1000 1000 - -"
      "d /media/movies 0775 1000 1000 - -"

      "d /var/lib/sonarr/config 0755 1000 1000 - -"
      "d /media/tv 0775 1000 1000 - -"

      "d /var/lib/bazarr/config 0755 1000 1000 - -"

      "d /var/lib/prowlarr/config 0755 1000 1000 - -"
    ];

    services.nginx.virtualHosts = {
      "${lidarr-fqdn}" = mkVirtualHost {
        fqdn = lidarr-fqdn;
        port = ports.lidarr;
      };
      "${radarr-fqdn}" = mkVirtualHost {
        fqdn = radarr-fqdn;
        port = ports.radarr;
      };
      "${sonarr-fqdn}" = mkVirtualHost {
        fqdn = sonarr-fqdn;
        port = ports.sonarr;
      };
      "${prowlarr-fqdn}" = mkVirtualHost {
        fqdn = prowlarr-fqdn;
        port = ports.prowlarr;
      };
      "${bazarr-fqdn}" = mkVirtualHost {
        fqdn = bazarr-fqdn;
        port = ports.bazarr;
      };
    };
  };
}
