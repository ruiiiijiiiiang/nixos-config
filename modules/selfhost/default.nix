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
    scanopy = {
      server.enable = mkEnableOption "Scanopy server";
      daemon.enable = mkEnableOption "Scanopy daemon";
    };
    stirlingpdf = {
      enable = mkEnableOption "Stirling-PDF document tools";
    };
    suricata = {
      enable = mkEnableOption "Suricata IDS/IPS";
      interfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Interfaces to monitor";
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
    yourls = {
      enable = mkEnableOption "YOURLS URL shortener";
    };
  };
}
