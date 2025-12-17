{ ... }:

{
  selfhost = {
    atuin.enable = true;
    bentopdf.enable = true;
    cloudflared.enable = true;
    microbin.enable = true;
    monit.enable = true;
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
