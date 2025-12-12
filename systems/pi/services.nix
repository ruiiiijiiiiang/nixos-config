{ ... }:

{
  rui = {
    acme.enable = true;
    atuin.enable = true;
    bentopdf.enable = true;
    beszel.enable = true;
    cloudflared.enable = true;
    dns.enable = true;
    homeassistant.enable = true;
    microbin.enable = true;
    monit.enable = true;
    nginx.enable = true;
    portainer.enable = true;
    seafile.enable = false;
    syncthing = {
      enable = true;
      proxied = true;
    };
    vaultwarden.enable = true;
    website.enable = true;
  };

  virtualisation = {
    oci-containers = {
      backend = "podman";
    };
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
  };

  services = {
    logrotate.enable = true;
  };
}
