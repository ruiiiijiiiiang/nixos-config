{
  imports = [
    ../../modules
  ];

  system.stateVersion = "25.11";
  networking.hostName = "vm-app";

  custom = {
    server = {
      network.enable = true;
      security.enable = true;
      services.enable = true;
    };

    vm = {
      hardware.enable = true;
      disks = {
        enableMain = true;
        enableStorage = true;
      };
    };

    selfhost = {
      atuin.enable = true;
      cloudflared.enable = false;
      dawarich.enable = true;
      immich.enable = true;
      homepage.enable = true;
      karakeep.enable = true;
      memos.enable = true;
      microbin.enable = true;
      nginx.enable = true;
      opencloud.enable = true;
      paperless.enable = true;
      pocketid.enable = true;
      reitti.enable = true;
      stirlingpdf.enable = true;
      syncthing = {
        enable = true;
        proxied = true;
      };
      vaultwarden.enable = true;
      website.enable = true;
      yourls.enable = true;

      beszel.agent.enable = true;
      dockhand.agent.enable = true;
      prometheus.exporters = {
        nginx.enable = true;
        node.enable = true;
        podman.enable = true;
      };
      scanopy.daemon.enable = true;
      wazuh.agent.enable = true;
    };
  };
}
