{
  config,
  consts,
  helpers,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) hardware;
  inherit (helpers) parsePciAddress;
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
      cpu.mode = "host-passthrough";
      vcpu.placement = "static";

      os.firmware = "efi";

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
              tag = [ { id = libvirtCfg.vlanId; } ];
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
              address = parsePciAddress hardware.gpu.address;
            };
          }
        ];

        rng = [
          {
            model = "virtio";
            backend = {
              model = "random";
              source = "/dev/urandom";
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

      clock = {
        offset = "utc";
        timer = [
          {
            name = "rtc";
            tickpolicy = "catchup";
          }
          {
            name = "pit";
            tickpolicy = "delay";
          }
          {
            name = "hpet";
            present = false;
          }
          {
            name = "kvmclock";
            present = true;
          }
        ];
      };
    };
in
{
  imports = [
    inputs.NixVirt.nixosModules.default
  ];

  options.custom.roles.headless.hypervisor.libvirt = with lib; {
    enable = mkEnableOption "Enable libvirt hypervisor host";
    guests = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Guest VM names to define.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.roles.headless.hypervisor.networking.enable;
        message = "Libvirt hypervisor requires the networking role (LAN bridge is referenced in domain XML).";
      }
      {
        assertion = config.custom.roles.headless.hypervisor.networking.lanBridge != null;
        message = "Libvirt hypervisor requires networking.lanBridge.";
      }
      {
        assertion =
          let
            guestConfigs = lib.filterAttrs (name: _: lib.elem name cfg.guests) nixosConfigurations;
            matching = lib.filterAttrs (name: hasGpuPassthrough) guestConfigs;
          in
          lib.length (lib.attrNames matching) <= 1;
        message = "Libvirt hypervisor supports GPU passthrough for at most one guest.";
      }
    ];

    environment.systemPackages = with pkgs; [
      bridge-utils
      pciutils
      usbutils
      virt-manager
      virtiofsd
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
                    vcpu.count = libvirtCfg.cpu;
                    memory.count = libvirtCfg.memory;
                    virtio_video = config.custom.platforms.vm.kernel.workstation or false;
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
        "vfio"
        "vfio_pci"
        "vfio-pci.ids=${hardware.gpu.pci}"
        "vfio_iommu_type1"
        "video=efifb:off"
      ];
      initrd.kernelModules = [
        "vfio"
        "vfio_pci"
        "vfio_iommu_type1"
      ];
    };

    environment.etc = lib.mkIf (gpuPassthroughGuest != null) {
      # needed to handle AMD GPU reset bug when the guest doesn't shut down correctly
      "libvirt/hooks/qemu" = {
        mode = "0755";
        source = pkgs.writeShellScript "qemu-hook" /* bash */ ''
          GUEST_NAME="$1"
          OPERATION="$2"
          SUB_OPERATION="$3"

          GPU_PCI="${hardware.gpu.address}"
          TARGET_VM="${gpuPassthroughGuest}"

          if [ "$GUEST_NAME" == "$TARGET_VM" ]; then
            if [ "$OPERATION" == "release" ]; then
              if [ -e "/sys/bus/pci/devices/$GPU_PCI/remove" ]; then
                echo "libvirt-qemu-hook: Removing AMD APU $GPU_PCI from bus..." | ${pkgs.systemd}/bin/systemd-cat -t libvirt-qemu-hook
                echo 1 > "/sys/bus/pci/devices/$GPU_PCI/remove"
                ${pkgs.coreutils}/bin/sleep 1
                echo 1 > /sys/bus/pci/rescan
                ${pkgs.coreutils}/bin/sleep 1
                echo "libvirt-qemu-hook: PCIe rescan complete for $TARGET_VM." | ${pkgs.systemd}/bin/systemd-cat -t libvirt-qemu-hook
              else
                echo "libvirt-qemu-hook: Device $GPU_PCI not found on bus, skipping reset." | ${pkgs.systemd}/bin/systemd-cat -t libvirt-qemu-hook
              fi
            fi
          fi
        '';
      };
    };
  };
}
