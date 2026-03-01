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
  cfg = config.custom.roles.hypervisor.provisioning;

  guests = lib.filterAttrs (
    hostname: nixosConfiguration: nixosConfiguration.config.libvirtGuest.enable
  ) nixosConfigurations;

  mkLibvirtBase = guest: {
    name = guest;
    uuid = hardware.uuids.${guest};

    cpu = {
      mode = "host-passthrough";
    };

    os = {
      type = "hvm";
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

    features = {
      acpi = { };
      apic = { };
    };

    devices = {
      emulator = "${pkgs.qemu_kvm}/bin/qemu-kvm";

      disk = [
        {
          type = "file";
          device = "disk";
          driver = {
            name = "qemu";
            type = "qcow2";
            discard = "unmap";
          };
          source = {
            file = "/var/lib/libvirt/images/${guest}.qcow2";
          };
          target = {
            dev = "vda";
            bus = "virtio";
          };
        }
      ];

      devices = {
        interface = [
          {
            type = "bridge";
            mac = {
              address = hardware.macs.${guest};
            };
            source = {
              bridge = cfg.lanBridge;
            };
            vlan = {
              tag = [ { id = vlan-ids.infra; } ];
            };
            model = {
              type = "virtio";
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
  };

  mkProvisionDiskService =
    { guest, size }:
    {
      systemd.services."provision-${guest}-disk" = {
        description = "Provision declarative qcow2 disk for ${guest}";
        wantedBy = [ "multi-user.target" ];
        before = [ "libvirtd.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = /* bash */ ''
          TARGET_DIR="/var/lib/libvirt/images"
          TARGET_DISK="$TARGET_DIR/${guest}.qcow2"

          mkdir -p "$TARGET_DIR"

          if [ ! -f "$TARGET_DISK" ]; then
            echo "Provisioning new ${size} virtual disk for ${guest}..."
            ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$TARGET_DISK" "$size"
            chown root:root "$TARGET_DISK"
            chmod 0644 "$TARGET_DISK"
          fi
        '';
      };
    };
in
{
  imports = [
    inputs.NixVirt.nixosModules.default
  ];

  options.custom.roles.hypervisor.provisioning = with lib; {
    enable = mkEnableOption "Hypervisor provisioning config";
    lanBridge = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Network bridge for LAN";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.lanBridge != null;
        message = "LAN bridge for hypervisor is missing";
      }
    ];

    systemd.services = lib.genAttrs guests (
      guest:
      let
        inherit (nixosConfigurations.${guest}) config;
      in
      mkProvisionDiskService {
        inherit guest;
        inherit (config.custom.libvirtGuest.disks.primary) size;
      }
    );

    virtualisation.libvirt = {
      enable = true;

      connections."qemu:///system" = {
        domains = map (
          guest:
          let
            inherit (nixosConfigurations.${guest}) config;
          in
          {
            active = true;
            definition = mkLibvirtBase guest // config.custom.libvirtGuest.config;
          }
        ) guests;
      };
    };
  };
}
