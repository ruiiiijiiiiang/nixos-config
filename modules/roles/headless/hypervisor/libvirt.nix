{
  config,
  consts,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (consts) hardware vlan-ids;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.roles.headless.hypervisor.libvirt;

  hasGpuPassthrough =
    nixosConfiguration: nixosConfiguration.config.custom.platforms.vm.kernel.gpuPassthrough or false;

  gpuPassthroughGuest =
    let
      guestConfigs = lib.filterAttrs (name: _: lib.elem name cfg.guests) nixosConfigurations;
      matching = lib.filterAttrs (name: hasGpuPassthrough) guestConfigs;
    in
    if matching == { } then null else (lib.head (lib.attrNames matching));

  mkLibvirtBase =
    { guest, libvirtCfg }:
    {
      cpu = {
        mode = "host-passthrough";
      };

      vcpu = {
        placement = "static";
        count = libvirtCfg.cpu;
      };

      memory = {
        count = libvirtCfg.memory;
        unit = "GiB";
      };

      memoryBacking = {
        source.type = "memfd";
        access.mode = "shared";
      };

      devices = {
        disk = [
          {
            type = "block";
            device = "disk";
            driver = {
              name = "qemu";
              type = "raw";
              cache = "none";
              io = "native";
            };
            source.dev = "/dev/${config.custom.platforms.minipc.disks.volumeGroup}/${guest}";
            target = {
              dev = "vda";
              bus = "virtio";
            };
          }
        ];

        filesystem = lib.mapAttrsToList (name: _: {
          type = "mount";
          accessmode = "passthrough";
          driver.type = "virtiofs";
          source.dir = "/mnt/${name}";
          target.dir = name;
        }) hardware.storage.external;

        interface = [
          {
            type = "bridge";
            mac = {
              address = hardware.macs.${guest};
            };
            source = {
              bridge = config.custom.roles.headless.hypervisor.networking.lanBridge;
            };
            vlan = {
              tag = [ { id = vlan-ids.infra; } ];
            };
            model = {
              type = "virtio";
            };
          }
        ];

        hostdev = lib.optionals (hasGpuPassthrough nixosConfigurations.${guest}) [
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

      channel = [
        {
          type = "unix";
          target = {
            type = "virtio";
            name = "org.qemu.guest_agent.0";
          };
        }
      ];
      serial = [
        {
          type = "pty";
          target = {
            type = "isa-serial";
            port = 0;
          };
        }
      ];
      console = [
        {
          type = "pty";
          target = {
            type = "serial";
            port = 0;
          };
        }
      ];
    };
in
{
  imports = [
    inputs.NixVirt.nixosModules.default
  ];

  options.custom.roles.headless.hypervisor.libvirt = with lib; {
    enable = mkEnableOption "Hypervisor host";
    guests = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of guest VM's";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bridge-utils
      pciutils
      usbutils
      virt-manager
    ];

    virtualisation = {
      libvirtd.qemu = {
        runAsRoot = true;
        swtpm.enable = true;
        verbatimConfig = ''
          user = "root"
          group = "root"
        '';
      };

      libvirt = {
        enable = true;
        connections."qemu:///system" = {
          domains = map (
            guest:
            let
              inherit (nixosConfigurations.${guest}) config;
              libvirtCfg = config.custom.platforms.vm.libvirt;
            in
            {
              active = libvirtCfg.autoStart;
              definition = inputs.NixVirt.lib.domain.writeXML (
                lib.foldl' lib.recursiveUpdate { } [
                  (inputs.NixVirt.lib.domain.templates.linux {
                    name = guest;
                    uuid = hardware.uuids.${guest};
                  })
                  (mkLibvirtBase { inherit guest libvirtCfg; })
                  libvirtCfg.extraConfigs
                ]
              );
            }
          ) cfg.guests;
        };
      };
    };

    boot = lib.mkIf (gpuPassthroughGuest != null) {
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "vfio-pci.ids=${hardware.gpu.pci}"
        "video=efifb:off"
      ];
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
      ];
    };

    environment.etc = lib.mkIf (gpuPassthroughGuest != null) {
      # needed to handle AMD GPU reset bug when the guest doesn't shut down correctly
      "libvirt/hooks/qemu" = {
        mode = "0755";
        text = /* bash */ ''
          #!/run/current-system/sw/bin/bash

          GUEST_NAME="$1"
          OPERATION="$2"
          SUB_OPERATION="$3"

          GPU_CONTROLLER="${hardware.gpu.controller}"
          TARGET_VM="${gpuPassthroughGuest}"

          if [ "$GUEST_NAME" == "$TARGET_VM" ]; then
            if [ "$OPERATION" == "release" ]; then
              if [ -e "/sys/bus/pci/devices/$GPU_CONTROLLER/remove" ]; then
                echo "libvirt-qemu-hook: Removing AMD APU $GPU_CONTROLLER from bus..." | systemd-cat -t libvirt-qemu-hook
                echo 1 > "/sys/bus/pci/devices/$GPU_CONTROLLER/remove"
                sleep 1
                echo 1 > /sys/bus/pci/rescan
                sleep 1
                echo "libvirt-qemu-hook: PCIe rescan complete for $TARGET_VM." | systemd-cat -t libvirt-qemu-hook
              else
                echo "libvirt-qemu-hook: Device $GPU_CONTROLLER not found on bus, skipping reset." | systemd-cat -t libvirt-qemu-hook
              fi
            fi
          fi
        '';
      };
    };
  };
}
