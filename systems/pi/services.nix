{ ... }:

{
  rui = {
    atuin.enable = true;
    bentopdf.enable = true;
    beszel.enable = true;
    cloudflared.enable = true;
    dns = {
      enable = true;
      subdomain = "pi-pihole";
    };
    homeassistant.enable = true;
    microbin.enable = true;
    monit = {
      enable = true;
      subdomain = "pi-monit";
    };
    nginx.enable = true;
    portainer.enable = true;
    syncthing = {
      enable = true;
      proxied = true;
    };
    vaultwarden.enable = true;
    website.enable = true;
  };
}
