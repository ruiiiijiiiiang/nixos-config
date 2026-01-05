{
  selfhost = {
    atuin.enable = true;
    cloudflared.enable = true;
    # dawarich.enable = true;
    immich.enable = true;
    homepage.enable = true;
    karakeep.enable = true;
    microbin.enable = true;
    nginx.enable = true;
    opencloud.enable = true;
    paperless.enable = true;
    pocketid.enable = true;
    portainer.enable = true;
    stirlingpdf.enable = true;
    syncthing = {
      enable = true;
      proxied = true;
    };
    vaultwarden.enable = true;
    website.enable = true;
    yourls.enable = true;

    beszel.agent.enable = true;
    prometheus.exporters = {
      nginx.enable = true;
      node.enable = true;
      podman.enable = true;
    };
    wazuh.agent.enable = true;
  };
}
