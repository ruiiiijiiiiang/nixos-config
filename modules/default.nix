{ lib, config, ... }:
with lib;
let
  cfg = config.rui;
in {
  imports = [
    ./acme
    ./atuin
    ./catppuccin
    ./cloudflared
    ./dns
    ./flatpak
    ./homeassistant
    ./microbin
    ./monit
    ./nginx
    ./syncthing
    ./vaultwarden

    ./devops
  ];

  options.rui = {
    acme = {
      enable = mkEnableOption "enable let's encrypt certificate for domain";
    };
    atuin = {
      enable = mkEnableOption "atuin server setup";
    };
    catppuccin = {
      enable = mkEnableOption "custom catppuccin theme setup";
    };
    cloudflared = {
      enable = mkEnableOption "set up cloudflare access tunnel";
    };
    dns = {
      enable = mkEnableOption "enable unbound + pihole dns filtering";
    };
    flatpak = {
      enable = mkEnableOption "enable flatpak service and packages";
    };
    homeassistant = {
      enable = mkEnableOption "enable homeassistant with zwave server";
    };
    microbin = {
      enable = mkEnableOption "enable microbin";
    };
    monit = {
      enable = mkEnableOption "enable monit monitoring dashboard";
    };
    nginx = {
      enable = mkEnableOption "enable nginx as a reverse proxy";
    };
    syncthing = {
      enable = mkEnableOption "enable and configure syncthing service";
      proxied = mkEnableOption "put syncthing behind a reverse proxy";
    };
    vaultwarden = {
      enable = mkEnableOption "enable private bitwarden";
    };

    devops = {
      enable = mkEnableOption "enable devops tools";
    };
  };

  config.assertions = [
    {
      assertion = (cfg.atuin.enable ||
        cfg.dns.enable ||
        cfg.homeassistant.enable ||
        cfg.microbin.enable ||
        cfg.monit.enable ||
        cfg.syncthing.proxied ||
        cfg.vaultwarden.enable
      ) -> cfg.nginx.enable;
      message = "Error: You have enabled a service that requires a proxy server, but 'rui.nginx.enable' is false.";
    }
  ];
}
