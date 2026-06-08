{
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts)
    timeZone
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkVirtualHost mkOciUser;
  cfg = config.custom.services.observability.netalertx;
  fqdn = "${subdomains.${config.networking.hostName}.netalertx}.${domain}";
in
{
  options.custom.services.observability.netalertx = with lib; {
    enable = mkEnableOption "Enable NetAlertX Network Intruder Detector";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.netalertx = {
      image = "ghcr.io/netalertx/netalertx:latest";
      networks = [ "host" ];
      volumes = [
        "/var/lib/netalertx:/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = timeZone;
        TIMEZONE = timeZone;
        PORT = toString ports.netalertx;
        NETALERTX_UID = toString oci-uids.netalertx;
        NETALERTX_GID = toString oci-uids.netalertx;
      };
      extraOptions = [
        "--read-only"
        "--read-only-tmpfs=false"
        "--cap-drop=all"
        "--cap-add=CHOWN"
        "--cap-add=SETGID"
        "--cap-add=SETUID"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_BIND_SERVICE"
        "--cap-add=NET_RAW"
        "--tmpfs=/tmp:rw,noexec,nosuid,nodev,mode=1777"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    users = mkOciUser "netalertx";

    systemd.tmpfiles.rules = [
      "d /var/lib/netalertx 0750 ${toString oci-uids.netalertx} ${toString oci-uids.netalertx} - -"
      "d /var/lib/netalertx/config 0750 ${toString oci-uids.netalertx} ${toString oci-uids.netalertx} - -"
      "d /var/lib/netalertx/db 0750 ${toString oci-uids.netalertx} ${toString oci-uids.netalertx} - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.netalertx;
    };
  };
}
