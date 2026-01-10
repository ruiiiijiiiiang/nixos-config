{ lib, ... }:
{
  imports = [
    ./atuin
    ./bentopdf
    ./beszel
    ./cloudflared
    ./dawarich
    ./dns
    ./dockhand
    ./dyndns
    ./gatus
    ./homeassistant
    ./homepage
    ./immich
    ./karakeep
    ./memos
    ./microbin
    ./monit
    ./nextcloud
    ./nginx
    ./opencloud
    ./paperless
    ./pocketid
    ./portainer
    ./prometheus
    ./reitti
    ./router
    ./scanopy
    ./stirlingpdf
    ./suricata
    ./syncthing
    ./vaultwarden
    ./wazuh
    ./website
    ./yourls
  ];

  options.custom.selfhost = with lib; {
    atuin = {
      enable = mkEnableOption "Atuin shell history sync server";
    };
    bentopdf = {
      enable = mkEnableOption "BentoPDF PDF service";
    };
    beszel = {
      hub.enable = mkEnableOption "Beszel monitoring hub";
      agent.enable = mkEnableOption "Beszel monitoring agent";
    };
    cloudflared = {
      enable = mkEnableOption "Cloudflare access tunnel";
    };
    dawarich = {
      enable = mkEnableOption "Dawarich GPS tracking service";
    };
    dockhand = {
      server.enable = mkEnableOption "Dockhand container management";
      agent.enable = mkEnableOption "Hawser container agent";
    };
    dns = {
      enable = mkEnableOption "Unbound + Pi-hole DNS filtering";
    };
    dyndns = {
      enable = mkEnableOption "dynamic DNS service";
    };
    gatus = {
      enable = mkEnableOption "Gatus monitoring dashboard";
    };
    immich = {
      enable = mkEnableOption "Immich photo and video storage";
    };
    karakeep = {
      enable = mkEnableOption "Karakeep service";
    };
    memos = {
      enable = mkEnableOption "Memos service";
    };
    homeassistant = {
      enable = mkEnableOption "Home Assistant with Z-Wave server";
    };
    homepage = {
      enable = mkEnableOption "Homepage dashboard";
    };
    microbin = {
      enable = mkEnableOption "MicroBin pastebin service";
    };
    monit = {
      enable = mkEnableOption "Monit monitoring dashboard";
    };
    nextcloud = {
      enable = mkEnableOption "Nextcloud file sync and collaboration";
    };
    nginx = {
      enable = mkEnableOption "Nginx reverse proxy";
    };
    opencloud = {
      enable = mkEnableOption "OpenCloud file server";
    };
    paperless = {
      enable = mkEnableOption "Paperless-ngx document management";
    };
    pocketid = {
      enable = mkEnableOption "PocketID authentication service";
    };
    portainer = {
      enable = mkEnableOption "Portainer container management";
    };
    prometheus = {
      server.enable = mkEnableOption "Prometheus metrics server";
      exporters = {
        nginx.enable = mkEnableOption "Prometheus Nginx exporter";
        node.enable = mkEnableOption "Prometheus Node exporter";
        podman.enable = mkEnableOption "Prometheus Podman exporter";
      };
    };
    reitti = {
      enable = mkEnableOption "Reitti route planning service";
    };
    router = {
      enable = mkEnableOption "Network router";
      wanInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Interface connecting to the WAN";
      };
      lanInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Interface connecting to the LAN";
      };
    };
    scanopy = {
      server.enable = mkEnableOption "Scanopy server";
      daemon.enable = mkEnableOption "Scanopy daemon";
    };
    stirlingpdf = {
      enable = mkEnableOption "Stirling-PDF document tools";
    };
    suricata = {
      enable = mkEnableOption "Suricata IDS/IPS";
      wanInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Interface connecting to the WAN";
      };
      lanInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Interface connecting to the LAN";
      };
    };
    syncthing = {
      enable = mkEnableOption "Syncthing file synchronization";
      proxied = mkEnableOption "Syncthing behind reverse proxy";
    };
    vaultwarden = {
      enable = mkEnableOption "Vaultwarden password manager";
    };
    wazuh = {
      server.enable = mkEnableOption "Wazuh security monitoring server";
      agent.enable = mkEnableOption "Wazuh security monitoring agent";
    };
    website = {
      enable = mkEnableOption "Personal website hosting";
    };
    wireguard = {
      server = {
        enable = mkEnableOption "WireGuard VPN server";
        privateKeyFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to WireGuard server private key";
        };
        interface = mkOption {
          type = types.str;
          description = "Interface to use for WireGuard server";
          default = "wg0";
        };
      };
      client = {
        enable = mkEnableOption "WireGuard VPN client";
        privateKeyFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to WireGuard client private key";
        };
        presharedKeyFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to WireGuard client preshared key";
        };
      };
    };
    yourls = {
      enable = mkEnableOption "YOURLS URL shortener";
    };
  };
}
