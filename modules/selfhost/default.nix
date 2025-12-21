{ lib, config, ... }:
with lib;
{
  imports = [
    ./atuin
    ./bentopdf
    ./beszel
    ./cloudflared
    ./dawarich
    ./dns
    ./dyndns
    ./homeassistant
    ./homepage
    ./immich
    ./microbin
    ./monit
    ./nginx
    ./paperless
    ./portainer
    ./syncthing
    ./vaultwarden
    ./website
    ./yourls
  ];

  options.selfhost = {
    atuin = {
      enable = mkEnableOption "enable atuin server";
    };
    bentopdf = {
      enable = mkEnableOption "enable bentopdf pdf service";
    };
    beszel = {
      enable = mkEnableOption "enable beszel for service monitoring";
    };
    cloudflared = {
      enable = mkEnableOption "set up cloudflare access tunnel";
    };
    dawarich = {
      enable = mkEnableOption "enable dawarich gps service";
    };
    dns = {
      enable = mkEnableOption "enable unbound + pihole dns filtering";
    };
    dyndns = {
      enable = mkEnableOption "enable dynamic dns service";
    };
    immich = {
      enable = mkEnableOption "enable immich image storage";
    };
    homeassistant = {
      enable = mkEnableOption "enable homeassistant with zwave server";
    };
    homepage = {
      enable = mkEnableOption "enable homepage dashboard";
    };
    microbin = {
      enable = mkEnableOption "enable microbin paste-bin";
    };
    monit = {
      enable = mkEnableOption "enable monit monitoring dashboard";
    };
    nginx = {
      enable = mkEnableOption "enable nginx as a reverse proxy";
    };
    paperless = {
      enable = mkEnableOption "enable paperless document management";
    };
    portainer = {
      enable = mkEnableOption "enable portainer for managing docker containers";
    };
    syncthing = {
      enable = mkEnableOption "enable and configure syncthing service";
      proxied = mkEnableOption "put syncthing behind a reverse proxy";
    };
    vaultwarden = {
      enable = mkEnableOption "enable private bitwarden secret manager";
    };
    website = {
      enable = mkEnableOption "enable personal website hosting";
    };
    yourls = {
      enable = mkEnableOption "enable yourls url shortener";
    };
  };

  config.assertions = [
    {
      assertion =
        let
          cfg = config.selfhost;
        in
        (
          cfg.atuin.enable
          || cfg.bentopdf.enable
          || cfg.beszel.enable
          || cfg.dawarich.enable
          || cfg.dns.enable
          || cfg.homeassistant.enable
          || cfg.homepage.enable
          || cfg.immich.enable
          || cfg.microbin.enable
          || cfg.monit.enable
          || cfg.paperless.enable
          || cfg.portainer.enable
          || cfg.syncthing.proxied
          || cfg.vaultwarden.enable
          || cfg.website.enable
          || cfg.yourls.enable
        )
        -> cfg.nginx.enable;
      message = "Error: You have enabled a service that requires a proxy server, but 'selfhost.nginx.enable' is false.";
    }
  ];
}
