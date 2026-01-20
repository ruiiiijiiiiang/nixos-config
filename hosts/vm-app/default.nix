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
      hardware = {
        enable = true;
        gpuPassthrough = true;
      };
      disks = {
        enableMain = true;
        enableStorage = true;
        enableScratch = true;
      };
    };

    services = {
      apps = {
        office = {
          memos.enable = true;
          opencloud.enable = true;
          paperless.enable = true;
          stirlingpdf.enable = true;
        };
        tools = {
          arr.enable = true;
          atuin.enable = true;
          dawarich.enable = true;
          karakeep.enable = true;
          microbin.enable = true;
          reitti.enable = true;
          syncthing = {
            enable = true;
            proxied = true;
          };
        };
        media = {
          immich.enable = true;
          jellyfin.enable = true;
        };
        security = {
          pocketid.enable = true;
          vaultwarden.enable = true;
        };
        web = {
          homepage.enable = true;
          website.enable = true;
        };
      };

      networking = {
        cloudflared.enable = false;
        nginx.enable = true;
        torrent.enable = true;
      };

      observability = {
        beszel.agent.enable = true;
        dockhand.agent.enable = true;
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
        };
        wazuh.agent.enable = true;
      };
    };
  };
}
