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
      image = "jellyfin/jellyfin:latest";
      autoStart = true;
      ports = [ "${addresses.localhost}:${toString ports.jellyfin}:${toString ports.jellyfin}" ];
      volumes = [
        "/var/lib/jellyfin/config:/config"
        "/var/lib/jellyfin/cache:/cache"
        "/media:/media"
      ];
      environment = {
        "LIBVA_DRIVER_NAME" = "radeonsi";
      };
      devices = [
        "/dev/dri/renderD128:/dev/dri/renderD128"
        "/dev/dri/card0:/dev/dri/card0"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/jellyfin/config 0755 1000 1000 - -"
      "d /var/lib/jellyfin/cache 0755 1000 1000 - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.jellyfin;
      };
    };
  };
}
