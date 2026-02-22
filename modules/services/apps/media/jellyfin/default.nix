{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    timeZone
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
    enable = mkEnableOption "Jellyfin media stream";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      ports = [ "${addresses.localhost}:${toString ports.jellyfin}:${toString ports.jellyfin}" ];
      volumes = [
        "/var/lib/jellyfin/config:/config"
        "/media:/media"
        "jellyfin-cache:/cache"
      ];
      environment = {
        TZ = timeZone;
        PUID = toString oci-uids.jellyfin;
        PGID = toString oci-uids.arr;
        UMASK_SET = "002";
        LIBVA_DRIVER_NAME = "radeonsi";
      };
      devices = [
        "/dev/dri/card0:/dev/dri/card0"
      ]
      ++ lib.optional config.custom.platform.vm.hardware.gpuPassthrough "/dev/dri/renderD128:/dev/dri/renderD128";
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
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.jellyfin;
      };
    };
  };
}
