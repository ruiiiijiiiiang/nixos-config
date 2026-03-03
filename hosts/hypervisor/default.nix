{ consts, ... }:
let
  inherit (consts) addresses vlan-ids;
  wanInterface = "eno1";
  lanInterface = "enxc8a362bf0bb3";
  wanBridge = "vmbr0";
  lanBridge = "vmbr1";
in
{
  system.stateVersion = "25.11";
  networking.hostName = "hypervisor";

  custom = {
    platforms.minipc = {
      kernel.enable = true;
      disks.enable = true;
    };

    roles.headless = {
      networking = {
        enable = true;
        trustedInterfaces = [ lanInterface ];
      };
      podman.enable = true;
      security.enable = true;
      services.enable = true;

      hypervisor = {
        networking = {
          enable = true;
          inherit
            wanInterface
            lanInterface
            wanBridge
            lanBridge
            ;
          vlanId = vlan-ids.infra;
        };

        libvirt = {
          enable = true;
          guests = [
            "vm-network"
            "vm-app"
            "vm-monitor"
          ];
          volumeGroup = "vg-nvme";
        };
      };
    };

    services = {
      networking.nginx.enable = true;

      infra.cockpit.enable = true;

      observability = {
        beszel.agent = {
          enable = true;
          interface = lanInterface;
        };
        dockhand.agent = {
          enable = true;
          interface = lanInterface;
        };
        loki.agent = {
          enable = true;
          serverAddress = addresses.infra.hosts.vm-monitor;
        };
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
          interface = lanInterface;
        };
      };

      security = {
        fail2ban.enable = true;
        wazuh.agent = {
          enable = true;
          interface = lanInterface;
        };
      };
    };
  };
}
