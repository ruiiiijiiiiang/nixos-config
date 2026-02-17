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
  cfg = config.custom.services.observability.dockhand.server;
  fqdn = "${subdomains.${config.networking.hostName}.dockhand}.${domains.home}";
in
{
  options.custom.services.observability.dockhand.server = with lib; {
    enable = mkEnableOption "Dockhand container management";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      dockhand-server = {
        image = "docker.io/fnsys/dockhand:latest";
        ports = [ "${addresses.localhost}:${toString ports.dockhand.server}:3000" ];
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "/var/lib/dockhand:/app/data"
        ];
        environment = {
          PUID = toString oci-uids.dockhand;
          PGID = toString oci-uids.dockhand;
          NODE_TLS_REJECT_UNAUTHORIZED = "0";
        };
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        extraOptions = [
          "--group-add=${toString oci-uids.podman}"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/dockhand 0700 ${toString oci-uids.dockhand} ${toString oci-uids.dockhand} - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.dockhand.server;
    };
  };
}
