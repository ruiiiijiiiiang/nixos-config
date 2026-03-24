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
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.web.magicmirror;
  fqdn = "${subdomains.${config.networking.hostName}.magicmirror}.${domain}";
in
{
  options.custom.services.apps.web.magicmirror = with lib; {
    enable = mkEnableOption "Enable MagicMirror";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      magicmirror = {
        image = "docker.io/karsten13/magicmirror:latest";
        user = "${toString oci-uids.magicmirror}:${toString oci-uids.magicmirror}";
        ports = [ "${addresses.localhost}:${toString ports.magicmirror}:8080" ];
        volumes = [
          "/var/lib/magicmirror/config:/opt/magic_mirror/config"
          "/var/lib/magicmirror/modules:/opt/magic_mirror/modules"
          "/var/lib/magicmirror/custom.css:/opt/magic_mirror/css/custom.css"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "magicmirror";

    systemd.tmpfiles.rules = [
      "d /var/lib/magicmirror/config 0700 ${toString oci-uids.magicmirror} ${toString oci-uids.magicmirror} - -"
      "d /var/lib/magicmirror/modules 0700 ${toString oci-uids.magicmirror} ${toString oci-uids.magicmirror} - -"
      "f /var/lib/magicmirror/custom.css 0700 ${toString oci-uids.magicmirror} ${toString oci-uids.magicmirror} - -"
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.magicmirror;
      };
    };
  };
}
