{ consts, helpers, ... }:
let
  inherit (consts)
    vlan-ids
    ports
    addresses
    hardware
    ;
  inherit (helpers) getHostAddress;
  hostName = "hypervisor";
  volumeGroup = "vg-nvme";
  lanInterface = "enxc8a362bf0bb3";
  wlanInterface = "wlan0";
  lanBridge = "br0";
  vlanId = vlan-ids.infra;
  vlanInterface = "${lanBridge}.${toString vlanId}";
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
        inherit volumeGroup;
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
      packages.enable = true;
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
            ;
          guests = {
            vm-network = {
              pciDevices = [
                {
                  address = hardware.nic.address;
                  id = hardware.nic.id;
                }
              ];
              vlan = {
                trunk = true;
                tag = [
                  {
                    id = vlan-ids.home;
                    nativeMode = "untagged";
                  }
                  { id = vlan-ids.infra; }
                  { id = vlan-ids.dmz; }
                ];
              };
            };

            vm-app = {
              autoStart = false;
              pciDevices = [
                {
                  address = hardware.gpu.address;
                  id = hardware.gpu.id;
                }
              ];
              vlan = {
                tag = [ { id = vlan-ids.infra; } ];
              };
            };

            vm-monitor = {
              vlan = {
                tag = [ { id = vlan-ids.infra; } ];
              };
            };

            vm-public = {
              vlan = {
                tag = [ { id = vlan-ids.dmz; } ];
              };
            };

            vm-cyber = {
              autoStart = false;
              vlan = {
                tag = [ { id = vlan-ids.dmz; } ];
              };
              nixvirtExtraConfigs = {
                devices = {
                  graphics = [
                    {
                      type = "spice";
                      autoport = false;
                      port = ports.spice.vm-cyber;
                      listen = {
                        type = "address";
                        address = addresses.any;
                      };
                    }
                  ];
                  sound = [
                    {
                      model = "ich9";
                      audio = {
                        id = 1;
                      };
                    }
                  ];
                  audio = [
                    {
                      id = 1;
                      type = "spice";
                    }
                  ];
                  channel = [
                    {
                      type = "spicevmc";
                      target = {
                        type = "virtio";
                        name = "com.redhat.spice.0";
                      };
                    }
                    {
                      type = "unix";
                      target = {
                        type = "virtio";
                        name = "org.qemu.guest_agent.0";
                      };
                    }
                  ];
                };
              };
            };
          };
        };
        podman = {
          enable = true;
          autoUpdate.enable = true;
        };
        restic = {
          enable = true;
          repo = backupPath;
        };
        smartd.enable = true;
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
          serverAddress = getHostAddress "vm-monitor";
        };
        prometheus.exporters = {
          libvirt.enable = true;
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
          smartctl.enable = true;
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
