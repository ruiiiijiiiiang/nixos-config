{ ... }:

{
  rui = {
    acme.enable = true;
    atuin.enable = true;
    bentopdf.enable = true;
    cloudflared.enable = true;
    dns.enable = true;
    homeassistant.enable = true;
    microbin.enable = true;
    monit.enable = true;
    nginx.enable = true;
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
      autoPrune.enable = true;
    };
  };

  services = {
    logrotate.enable = true;
  };
}
