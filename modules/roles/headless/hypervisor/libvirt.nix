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
  inherit (consts) username hardware;
  inherit (helpers) parsePciAddress;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.roles.headless.hypervisor.libvirt;

  getPassthroughGuest =
    hw:
    let
      guestConfigs = lib.filterAttrs (name: _: lib.elem name cfg.guests) nixosConfigurations;
      matching = lib.filterAttrs (
        _: c: c.config.custom.platforms.vm.kernel.hardwarePassthrough == hw
      ) guestConfigs;
    in
    if matching == { } then null else lib.head (lib.attrNames matching);

  passthroughIds =
    lib.concatMap (hw: lib.optional (getPassthroughGuest hw != null) hardware.${hw}.id)
      [
        "gpu"
        "nic"
      ];

  mkLibvirtBase =
    { guest, libvirtCfg }:
    {
      vcpu.placement = "static";

      os = {
        loader = {
          readonly = true;
          secure = false;
          type = "pflash";
          # This path needs to be hardcoded otherwise it defaults to edk2-x86_64-secure-code.fd and enables secure boot.
          # I've tried other methods to disable secure boot and setting this path is the only way that worked.
          path = "/run/libvirt/nix-ovmf/edk2-x86_64-code.fd";
        };
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
              discard = "unmap";
            };
            source.dev = "/dev/${config.custom.platforms.minipc.disks.volumeGroup}/${guest}";
            target = {
              dev = "vda";
              bus = "virtio";
            };
          }
        ];

        filesystem = [
          {
            type = "mount";
            accessmode = "passthrough";
            driver.type = "virtiofs";
            source.dir = "/mnt/external";
            target.dir = "usb_hdd";
          }
        ];

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

        hostdev =
          let
            inherit (nixosConfigurations.${guest}.config.custom.platforms.vm.kernel) hardwarePassthrough;
          in
          lib.optionals (hardwarePassthrough != null) [
            {
              mode = "subsystem";
              type = "pci";
              managed = true;
              source = {
                address = parsePciAddress hardware.${hardwarePassthrough}.address;
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

        panic = [
          {
            model = "isa";
          }
        ];

        video = [
          {
            model = {
              type = "virtio";
            };
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
    environment.systemPackages = with pkgs; [
      pciutils
      usbutils
      virtiofsd
    ];

    virtualisation = {
      libvirtd.qemu = {
        runAsRoot = true;
        package = pkgs.qemu_kvm;
        vhostUserPackages = with pkgs; [ virtiofsd ];
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
                    memory = {
                      count = libvirtCfg.memory;
                      unit = "GiB";
                    };
                    virtio_video = false;
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

    # Temporary fix
    systemd.services."virt-secret-init-encryption" = {
      preStart = ''
        mkdir -p /var/lib/libvirt/secrets
        chmod 0711 /var/lib/libvirt
        chmod 0700 /var/lib/libvirt/secrets
      '';

      serviceConfig = {
        ExecStart = lib.mkForce [
          ""
          "${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/head -c 32 /dev/random | ${pkgs.systemd}/bin/systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key'"
        ];
      };

      path = [ pkgs.systemd ];
    };

    boot = lib.mkIf (passthroughIds != [ ]) {
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "vfio"
        "vfio_pci"
        "vfio-pci.ids=${lib.concatStringsSep "," passthroughIds}"
        "vfio_iommu_type1"
        "video=efifb:off"
      ];
      initrd.kernelModules = [
        "vfio"
        "vfio_pci"
        "vfio_iommu_type1"
      ];
    };

    environment.etc =
      let
        gpuPassthroughGuest = getPassthroughGuest "gpu";
      in
      lib.mkIf (gpuPassthroughGuest != null) {
        # This is needed to handle AMD GPU reset bug when the guest doesn't shut down correctly.
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

    users.users.${username}.extraGroups = [ "libvirtd" ];
  };
}
