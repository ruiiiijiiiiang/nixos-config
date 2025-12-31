{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  boot = {
    tmp.useTmpfs = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "rootdelay=5" ];
  };

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      storage = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
        content = {
          type = "gpt";
          partitions = {
            bulk = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/data";
                mountOptions = [
                  "defaults"
                  "nofail"
                ];
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/var" = {
    device = "/data/var";
    options = [
      "bind"
      "nofail"
    ];
    depends = [ "/data" ];
  };

  fileSystems."/home" = {
    device = "/data/home";
    options = [
      "bind"
      "nofail"
    ];
    depends = [ "/data" ];
  };

  services.qemuGuest.enable = true;
}
