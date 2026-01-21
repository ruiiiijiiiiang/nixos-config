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
    oci-uids
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.media.jellyfin;
  fqdn = "${subdomains.${config.networking.hostName}.jellyfin}.${domains.home}";
in
{
  options.custom.services.apps.media.jellyfin = with lib; {
    enable = mkEnableOption "Jellyfin media service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.jellyfin = {
      image = "docker.io/jellyfin/jellyfin:latest";
      autoStart = true;
      ports = [ "${addresses.localhost}:${toString ports.jellyfin}:${toString ports.jellyfin}" ];
      volumes = [
        "/var/lib/jellyfin/config:/config"
        "/var/lib/jellyfin/cache:/cache"
        "/media:/media"
      ];
      environment = {
        UMASK_SET = "002";
        LIBVA_DRIVER_NAME = "radeonsi";
      };
      devices = [
        "/dev/dri/renderD128:/dev/dri/renderD128"
        "/dev/dri/card0:/dev/dri/card0"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    users.users.jellyfin = {
      uid = oci-uids.jellyfin;
      group = "arr";
      isSystemUser = true;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/jellyfin/config 0755 ${toString oci-uids.jellyfin} ${toString oci-uids.arr} - -"
      "d /var/lib/jellyfin/cache 0755 ${toString oci-uids.jellyfin} ${toString oci-uids.arr} - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.jellyfin;
      };
    };
  };
}
