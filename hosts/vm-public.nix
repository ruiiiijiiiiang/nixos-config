{ helpers, inputs, ... }:
let
  inherit (helpers) getHostAddress;
  hostName = "vm-public";
  lanInterface = "lan0";
in
{
  imports = [
    inputs.nixos-vm-provisioner.nixosModules.guest-base
  ];

  system.stateVersion = "25.11";
  networking.hostName = hostName;

  nixos-vm-provisioner.guest.enable = true;

  custom = {
    platforms.vm = {
      kernel.enable = true;
      disks.enable = true;
      networking = {
        enable = true;
        inherit lanInterface;
      };
    };

    roles.headless = {
      networking.enable = true;
      packages.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
      apps = {
        tools.microbin.enable = true;
        web = {
          searxng.enable = true;
          website.enable = true;
        };
        ai.zeroclaw.enable = true;
      };

      infra = {
        podman = {
          enable = true;
          autoUpdate.enable = true;
        };
      };

      networking.nginx.enable = true;

      observability = {
        beszel.agent.enable = true;
        dockhand.agent.enable = true;
        loki.agent = {
          enable = true;
          serverAddress = getHostAddress "vm-monitor";
        };
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
        };
      };

      security = {
        fail2ban.enable = true;
        krawl.enable = true;
        wazuh.agent = {
          enable = true;
          serverAddress = getHostAddress "vm-monitor";
        };
      };
    };
  };
}
