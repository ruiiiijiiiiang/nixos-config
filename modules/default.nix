{ lib, config, ... }:
with lib;
{
  imports = [
    ./atuin
    ./bentopdf
    ./beszel
    ./catppuccin
    ./cloudflared
    ./devops
    ./dns
    ./dyndns
    ./flatpak
    ./homeassistant
    ./immich
    ./microbin
    ./monit
    ./nginx
    ./paperless
    ./portainer
    ./syncthing
    ./vaultwarden
    ./website
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
          || cfg.dns.enable
          || cfg.homeassistant.enable
          || cfg.immich.enable
          || cfg.microbin.enable
          || cfg.monit.enable
          || cfg.paperless.enable
          || cfg.portainer.enable
          || cfg.syncthing.proxied
          || cfg.vaultwarden.enable
          || cfg.website.enable
        )
        -> cfg.nginx.enable;
      message = "Error: You have enabled a service that requires a proxy server, but 'rui.nginx.enable' is false.";
    }
  ];

  options.custom = {
    catppuccin = {
      enable = mkEnableOption "custom catppuccin theme setup";
    };
    flatpak = {
      enable = mkEnableOption "enable flatpak service and packages";
    };
    devops = {
      enable = mkEnableOption "enable devops tools";
    };
  };
}
