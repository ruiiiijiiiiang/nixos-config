{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) addresses hardware;
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-app";

  custom = {
    libvirtGuest = {
      enable = true;
      config = {
        memory = {
          count = 12288;
          unit = "MiB";
        };
        currentMemory = {
          count = 12288;
          unit = "MiB";
        };

        vcpu = {
          count = 10;
        };

        devices = {
          hostdev = lib.mkIf config.custom.libvirtGuest.gpuPassthrough [
            {
              mode = "subsystem";
              type = "pci";
              managed = true;
              source = {
                inherit (hardware.gpu) address;
              };
            }
          ];
        };
      };
      disks = {
        primary = {
          size = "200GB";
        };
        storage = {
          enable = true;
          size = "1000GB";
        };
        scratch = {
          enable = true;
          size = "1000GB";
        };
      };
      gpuPassthrough = true;
    };

    platforms.vm = {
      hardware = {
        enable = true;
        inherit (config.custom.libvirtGuest) gpuPassthrough;
      };
      disks = {
        enableMain = true;
        enableStorage = true;
        enableScratch = true;
      };
    };

    roles.headless = {
      networking.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
      apps = {
        authentication = {
          pocketid.enable = true;
          vaultwarden.enable = true;
        };
        development = {
          bytestash.enable = true;
          forgejo.enable = true;
        };
        office = {
          memos.enable = true;
          opencloud.enable = true;
          paperless.enable = true;
        };
        tools = {
          arr.enable = true;
          atuin.enable = true;
          karakeep.enable = true;
          harmonia.enable = true;
          microbin.enable = true;
          reitti.enable = true;
          searxng.enable = true;
          syncthing = {
            enable = true;
            proxied = true;
          };
        };
        media = {
          immich.enable = true;
          jellyfin.enable = true;
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
        loki.agent = {
          enable = true;
          serverAddress = addresses.infra.hosts.vm-monitor;
        };
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
        };
      };

      security = {
        fail2ban.enable = true;
        wazuh.agent.enable = true;
      };
    };
  };
}
