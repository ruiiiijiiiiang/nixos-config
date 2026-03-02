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
  cfg = config.custom.roles.hypervisor.libvirt;

  guestGpuPassthrough =
    nixosConfiguration: nixosConfiguration.config.custom.platforms.vm.hardware.gpuPassthrough or false;

  gpuPassthroughEnabled = builtins.any guestGpuPassthrough (builtins.attrValues nixosConfigurations);

  gpuPassthroughGuest =
    let
      matching = lib.filterAttrs (name: guestGpuPassthrough) nixosConfigurations;
    in
    if matching == { } then null else (lib.head (lib.attrNames matching));

  mkLibvirtBase = guest: {
    cpu = {
      mode = "host-passthrough";
    };

    os = {
      loader = {
        readonly = true;
        type = "pflash";
        path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.fd";
      };
      nvram = {
        template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd";
      };
      boot = [ { dev = "hd"; } ];
    };

    memoryBacking = {
      source.type = "memfd";
      access.mode = "shared";
    };

    devices = {
      emulator = "${pkgs.qemu_kvm}/bin/qemu-kvm";

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
          source.dev = "/dev/${cfg.volumeGroup.name}/${guest}";
          target = {
            dev = "vda";
            bus = "virtio";
          };
        }
      ];

      filesystem = lib.mapAttrsToList (name: device: {
        type = "mount";
        accessmode = "passthrough";
        driver.type = "virtiofs";
        source.dir = device.path;
        target.dir = device.virtio-tag;
      }) hardware.storage.external;

      interface = [
        {
          type = "bridge";
          mac = {
            address = hardware.macs.${guest};
          };
          source = {
            bridge = config.custom.roles.hypervisor.networking.lanBridge;
          };
          vlan = {
            tag = [ { id = vlan-ids.infra; } ];
          };
          model = {
            type = "virtio";
          };
        }
      ];

      hostdev = lib.mkIf guestGpuPassthrough nixosConfigurations.${guest} [
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
    channel = [
      {
        type = "unix";
        target = {
          type = "virtio";
          name = "org.qemu.guest_agent.0";
        };
      }
    ];
  };
in
{
  imports = [
    inputs.NixVirt.nixosModules.default
  ];

  options.custom.roles.hypervisor.libvirt = with lib; {
    enable = mkEnableOption "Hypervisor host";
    volumeGroup = {
      enable = mkEnableOption "LVM volume group config";
      name = mkOption {
        type = types.str;
        default = "vg-0";
        description = "LVM volume group name";
      };
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
        ovmf.enable = true;
      };

      libvirt = {
        enable = true;
        connections."qemu:///system" = {
          domains =
            map
              (
                guest:
                let
                  inherit (nixosConfigurations.${guest}) config;
                in
                {
                  active = true;
                  definition = inputs.nixvirt.lib.domain.writeXML (
                    lib.foldl' lib.recursiveUpdate { } [
                      (inputs.nixvirt.lib.domain.templates.linux {
                        name = guest;
                        uuid = hardware.uuids.${guest};
                      })
                      (mkLibvirtBase guest)
                      config.custom.platforms.vm.libvirt.config
                    ]
                  );
                }
              )
              lib.filterAttrs
              (hostname: nixosConfiguration: nixosConfiguration.config.custom.platforms.vm.libvirt.enable)
              nixosConfigurations;
        };
      };
    };

    boot = lib.mkIf gpuPassthroughEnabled {
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

    environment.etc = lib.mkIf gpuPassthroughEnabled {
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
