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
        ports = [
          "${addresses.localhost}:${toString ports.arr.lidarr}:${toString ports.arr.lidarr}"
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.arr.lidarr}:${toString ports.arr.lidarr}"
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
        ports = [
          "${addresses.localhost}:${toString ports.arr.radarr}:${toString ports.arr.radarr}"
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.arr.radarr}:${toString ports.arr.radarr}"
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
        ports = [
          "${addresses.localhost}:${toString ports.arr.sonarr}:${toString ports.arr.sonarr}"
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.arr.sonarr}:${toString ports.arr.sonarr}"
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
        ports = [
          "${addresses.localhost}:${toString ports.arr.prowlarr}:${toString ports.arr.prowlarr}"
          "${
            addresses.home.hosts.${config.networking.hostName}
          }:${toString ports.arr.prowlarr}:${toString ports.arr.prowlarr}"
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
        ports = [ "${toString ports.arr.bazarr}:${toString ports.arr.bazarr}" ];
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
        ports = [ "${toString ports.arr.flaresolverr}:${toString ports.arr.flaresolverr}" ];
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
        port = ports.arr.lidarr;
      };
      "${radarr-fqdn}" = mkVirtualHost {
        fqdn = radarr-fqdn;
        port = ports.arr.radarr;
      };
      "${sonarr-fqdn}" = mkVirtualHost {
        fqdn = sonarr-fqdn;
        port = ports.arr.sonarr;
      };
      "${prowlarr-fqdn}" = mkVirtualHost {
        fqdn = prowlarr-fqdn;
        port = ports.arr.prowlarr;
      };
      "${bazarr-fqdn}" = mkVirtualHost {
        fqdn = bazarr-fqdn;
        port = ports.arr.bazarr;
      };
    };
  };
}
