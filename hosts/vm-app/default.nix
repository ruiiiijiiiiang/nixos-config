{ consts, ... }:
let
  inherit (consts) addresses vlan-ids;
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
        cpu = 8;
        memory = 12;
        vlanId = vlan-ids.infra;
        autoStart = true;
      };

      disks = {
        enable = true;
        size = 300;
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
          microbin.enable = true;
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
          karakeep.enable = true;
          searxng.enable = true;
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
