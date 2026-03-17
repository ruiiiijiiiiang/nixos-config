{ consts, ... }:
let
  inherit (consts) addresses vlan-ids;
  hostName = "vm-app";
  lanInterface = "lan0";
  vlanId = vlan-ids.infra;
  storagePath = "/mnt/usb-hdd-0/${hostName}/storage";
  mediaPath = "/mnt/usb-hdd-0/${hostName}/media";
  backupPath = "/mnt/usb-hdd-1/${hostName}/backup";
in
{
  system.stateVersion = "25.11";
  networking.hostName = hostName;

  custom = {
    platforms.vm = {
      kernel = {
        enable = true;
        hardwarePassthrough = "gpu";
      };

      libvirt = {
        enable = true;
        cpu = 8;
        memory = 12;
        inherit vlanId;
        autoStart = true;
      };

      disks = {
        enable = true;
        size = 300;
      };

      networking = {
        enable = true;
        inherit lanInterface;
      };
    };

    roles.headless = {
      networking.enable = true;
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
        media = {
          immich = {
            enable = true;
            inherit storagePath;
          };
          jellyfin = {
            enable = true;
            inherit mediaPath;
          };
        };
        office = {
          memos.enable = true;
          opencloud = {
            enable = true;
            inherit storagePath;
          };
          paperless = {
            enable = true;
            inherit storagePath;
          };
        };
        tools = {
          arr = {
            enable = true;
            inherit mediaPath;
          };
          atuin.enable = true;
          llm.enable = true;
          microbin.enable = true;
          syncthing = {
            enable = true;
            proxied = true;
          };
        };
        web = {
          homepage.enable = true;
          karakeep.enable = true;
          searxng.enable = true;
          website.enable = true;
        };
      };

      infra = {
        harmonia.enable = true;
        nfs.server.enable = true;
        podman = {
          enable = true;
          autoUpdate.enable = true;
          autoBackup = {
            enable = true;
            path = backupPath;
          };
        };
        restic = {
          enable = true;
          repo = backupPath;
          extraPaths = [ storagePath ];
        };
      };

      networking = {
        nginx.enable = true;
        torrent = {
          enable = true;
          inherit mediaPath;
        };
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
          restic.enable = true;
        };
      };

      security = {
        fail2ban.enable = true;
        wazuh.agent = {
          enable = true;
          serverAddress = addresses.infra.hosts.vm-monitor;
        };
      };
    };
  };
}
