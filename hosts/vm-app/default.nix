{ consts, ... }:
let
  inherit (consts) addresses;
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-app";

  custom = {
    platforms.vm = {
      kernel = {
        enable = true;
        gpuPassthrough = true;
      };

      libvirt = {
        enable = true;
        config = {
          vcpu = {
            count = 8;
          };
          memory = {
            count = 12;
          };
        };
      };

      disks = {
        enable = true;
        size = "300GB";
      };
    };

    roles.headless = {
      networking.enable = true;
      podman.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
      apps = {
        auth = {
          pocketid.enable = true;
          vaultwarden.enable = true;
        };
        development = {
          bytestash.enable = true;
          forgejo.enable = true;
        };
        location = {
          reitti.enable = true;
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
          microbin.enable = true;
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

      infra = {
        harmonia.enable = true;
      };

      networking = {
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
