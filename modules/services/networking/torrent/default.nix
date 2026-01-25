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
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.networking.torrent;
  fqdn = "${subdomains.${config.networking.hostName}.qbittorrent}.${domains.home}";
in
{
  options.custom.services.networking.torrent = with lib; {
    enable = mkEnableOption "Qbittorrent service protected by gluetun";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      wireguard-proton-private-key.file = ../../../../secrets/wireguard/proton-private-key.age;
    };

    virtualisation.oci-containers.containers = {
      gluetun = {
        image = "ghcr.io/qdm12/gluetun:latest";
        extraOptions = [
          "--cap-add=NET_ADMIN"
        ];
        environment = {
          TZ = timeZone;
          FIREWALL_OUTBOUND_SUBNETS = addresses.home.network;
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          SERVER_COUNTRIES = "United States";
          WIREGUARD_PRIVATE_KEY_SECRETFILE = "/wg_key";
          WIREGUARD_ADDRESSES = "10.2.0.2/32";
        };
        ports = [
          "${toString ports.qbittorrent}:${toString ports.qbittorrent}"
        ];
        volumes = [
          "${config.age.secrets.wireguard-proton-private-key.path}:/wg_key:ro"
        ];
        devices = [ "/dev/net/tun:/dev/net/tun" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        dependsOn = [ "gluetun" ];
        networks = [ "container:gluetun" ];
        environment = {
          TZ = timeZone;
          PUID = toString oci-uids.qbittorrent;
          PGID = toString oci-uids.arr;
          UMASK_SET = "002";
          WEBUI_PORT = "${toString ports.qbittorrent}";
        };
        volumes = [
          "/var/lib/qbittorrent/config:/config"
          "/media:/mnt"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users.users.qbittorrent = {
      uid = oci-uids.qbittorrent;
      group = "arr";
      isSystemUser = true;
    };

    systemd.tmpfiles.rules = [
      "d /media/downloads 0775 ${toString oci-uids.arr} ${toString oci-uids.arr} - -"
      "d /var/lib/qbittorrent/config 0755 ${toString oci-uids.qbittorrent} ${toString oci-uids.arr} - -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.qbittorrent;
    };
  };
}
