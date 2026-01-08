{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.vm.hardware;
in
{
  config = lib.mkIf cfg.enable {
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

    services.qemuGuest.enable = true;
  };
}
