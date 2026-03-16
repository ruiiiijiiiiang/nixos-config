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
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.media.jellyfin;
  fqdn = "${subdomains.${config.networking.hostName}.jellyfin}.${domain}";
in
{
  options.custom.services.apps.media.jellyfin = with lib; {
    enable = mkEnableOption "Enable Jellyfin";
    mediaPath = mkOption {
      type = types.str;
      description = "Path to store media data.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.mediaPath;
        message = "custom.services.apps.media.jellyfin.mediaPath must be an absolute path string.";
      }
    ];

    virtualisation.oci-containers.containers.jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      ports = [ "${addresses.localhost}:${toString ports.jellyfin}:${toString ports.jellyfin}" ];
      volumes = [
        "/var/lib/jellyfin/config:/config"
        "${cfg.mediaPath}:/media"
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
        "/dev/kfd:/dev/kfd"
        "/dev/dri:/dev/dri"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    users.users.jellyfin = {
      uid = oci-uids.jellyfin;
      group = "arr";
      isSystemUser = true;
      extraGroups = [
        "video"
        "render"
      ];
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
