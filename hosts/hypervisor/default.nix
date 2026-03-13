{ consts, ... }:
let
  inherit (consts) addresses vlan-ids;
  hostName = "hypervisor";
  lanInterface = "enxc8a362bf0bb3";
  lanBridge = "br0";
  vlanInterface = "${lanBridge}.${toString vlan-ids.infra}";
in
{
  system.stateVersion = "25.11";
  networking.hostName = hostName;

  custom = {
    platforms.minipc = {
      kernel.enable = true;
      disks = {
        enable = true;
        volumeGroup = "vg-nvme";
      };
    };

    roles.headless = {
      networking = {
        enable = true;
        trustedInterfaces = [ vlanInterface ];
      };
      security.enable = true;
      services.enable = true;

      hypervisor = {
        networking = {
          enable = true;
          inherit
            lanInterface
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
            "vm-cyber"
          ];
        };
      };
    };

    services = {
      infra = {
        nfs.server = {
          enable = true;
          interface = vlanInterface;
        };
        podman.enable = true;
      };

      networking.nginx.enable = true;

      observability = {
        beszel.agent = {
          enable = true;
          interface = vlanInterface;
        };
        cockpit.enable = true;
        dockhand.agent = {
          enable = true;
          interface = vlanInterface;
        };
        loki.agent = {
          enable = true;
          serverAddress = addresses.infra.hosts.vm-monitor;
        };
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
          interface = vlanInterface;
        };
      };

      security = {
        fail2ban.enable = true;
        wazuh.agent = {
          enable = true;
          interface = vlanInterface;
        };
      };
    };
  };
}
