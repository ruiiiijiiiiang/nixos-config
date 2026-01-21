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
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.tools.arr;
  lidarr-fqdn = "${subdomains.${config.networking.hostName}.lidarr}.${domains.home}";
  radarr-fqdn = "${subdomains.${config.networking.hostName}.radarr}.${domains.home}";
  sonarr-fqdn = "${subdomains.${config.networking.hostName}.sonarr}.${domains.home}";
  prowlarr-fqdn = "${subdomains.${config.networking.hostName}.prowlarr}.${domains.home}";
  bazarr-fqdn = "${subdomains.${config.networking.hostName}.bazarr}.${domains.home}";
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
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.lidarr}:${toString ports.lidarr}"
        ];
        environment = {
          TZ = timeZone;
          PUID = toString oci-uids.arr;
          PGID = toString oci-uids.arr;
          UMASK_SET = "002";
        };
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
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.radarr}:${toString ports.radarr}"
        ];
        environment = {
          TZ = timeZone;
          PUID = toString oci-uids.arr;
          PGID = toString oci-uids.arr;
          UMASK_SET = "002";
        };
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
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.sonarr}:${toString ports.sonarr}"
        ];
        environment = {
          TZ = timeZone;
          PUID = toString oci-uids.arr;
          PGID = toString oci-uids.arr;
          UMASK_SET = "002";
        };
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
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.prowlarr}:${toString ports.prowlarr}"
        ];
        environment = {
          TZ = timeZone;
          PUID = toString oci-uids.arr;
          PGID = toString oci-uids.arr;
          UMASK_SET = "002";
        };
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
        environment = {
          TZ = timeZone;
          PUID = toString oci-uids.arr;
          PGID = toString oci-uids.arr;
          UMASK_SET = "002";
        };
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
          TZ = timeZone;
          LOG_LEVEL = "info";
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "arr";

    systemd.tmpfiles.rules = [
      "d /var/lib/lidarr/config 0755 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"
      "d /media/music 0775 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"

      "d /var/lib/radarr/config 0755 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"
      "d /media/movies 0775 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"

      "d /var/lib/sonarr/config 0755 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"
      "d /media/tv 0775 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"

      "d /var/lib/bazarr/config 0755 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"

      "d /var/lib/prowlarr/config 0755 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"
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
