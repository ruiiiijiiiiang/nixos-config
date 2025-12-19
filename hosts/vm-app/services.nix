{ ... }:

{
  selfhost = {
    atuin.enable = true;
    bentopdf.enable = true;
    cloudflared.enable = true;
    immich.enable = true;
    homepage.enable = true;
    microbin.enable = true;
    monit.enable = true;
    nginx.enable = true;
    paperless.enable = true;
    portainer.enable = true;
    shlink.enable = true;
    syncthing = {
      enable = true;
      proxied = true;
    };
    vaultwarden.enable = true;
    website.enable = true;
  };
}
