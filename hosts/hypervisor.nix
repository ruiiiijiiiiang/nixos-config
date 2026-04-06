{ consts, ... }:
let
  inherit (consts) addresses vlan-ids;
  hostName = "hypervisor";
  volumeGroup = "vg-nvme";
  lanInterface = "enxc8a362bf0bb3";
  wlanInterface = "wlan0";
  lanBridge = "br0";
  vlanId = vlan-ids.infra;
  vlanInterface = "${lanBridge}.${toString vlanId}";

  guestVms = [
    "vm-network"
    "vm-app"
    "vm-monitor"
    "vm-cyber"
    "vm-public"
  ];
  backupPath = "/mnt/external/usb-hdd-1/${hostName}/backup";
in
{
  system.stateVersion = "25.11";
  networking.hostName = hostName;

  custom = {
    platforms.minipc = {
      kernel.enable = true;
      disks = {
        enable = true;
        inherit volumeGroup guestVms;
      };
      networking = {
        enable = true;
        inherit
          lanInterface
          wlanInterface
          lanBridge
          vlanId
          ;
      };
    };

    roles.headless = {
      networking = {
        enable = true;
        trustedInterfaces = [
          lanBridge
          vlanInterface
          wlanInterface
        ];
      };
      security.enable = true;
      services.enable = true;
    };

    services = {
      infra = {
        hypervisor = {
          enable = true;
          inherit
            lanBridge
            vlanId
            volumeGroup
            guestVms
            ;
        };
        nfs.server = {
          enable = true;
          interfaces = [ vlanInterface ];
        };
        podman = {
          enable = true;
          autoUpdate.enable = true;
        };
        restic = {
          enable = true;
          repo = backupPath;
        };
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
          # libvirt.enable = true;
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
