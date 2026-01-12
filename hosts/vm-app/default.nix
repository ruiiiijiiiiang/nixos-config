{
  system.stateVersion = "25.11";
  networking.hostName = "vm-app";

  custom = {
    roles.headless = {
      network.enable = true;
      security.enable = true;
      services.enable = true;
    };

    platform.vm = {
      hardware.enable = true;
      disks = {
        enableMain = true;
        enableStorage = true;
      };
    };

    services = {
      apps = {
        tools = {
          atuin.enable = true;
          dawarich.enable = true;
          karakeep.enable = true;
          microbin.enable = true;
          reitti.enable = true;
          syncthing = {
            enable = true;
            proxied = true;
          };
          yourls.enable = true;
        };
        media.immich.enable = true;
        web.homepage.enable = true;
        web.website.enable = true;
        office = {
          memos.enable = true;
          opencloud.enable = true;
          paperless.enable = true;
          stirlingpdf.enable = true;
        };
        security = {
          pocketid.enable = true;
          vaultwarden.enable = true;
        };
      };

      networking = {
        cloudflared.enable = false;
        nginx.enable = true;
      };

      observability = {
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
  };
}
