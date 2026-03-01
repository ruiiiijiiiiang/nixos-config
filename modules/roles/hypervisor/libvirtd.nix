{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) hardware;
  cfg = config.custom.roles.hypervisor.libvirtd;
in
{
  options.custom.roles.hypervisor.libvirtd = with lib; {
    enable = mkEnableOption "Libvirtd config";
    gpuPassthrough = mkEnableOption "GPU passthrough";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            runAsRoot = true;
            swtpm.enable = true;
            ovmf = {
              enable = true;
              packages = [ pkgs.OVMFFull.fd ];
            };
          };
        };

        environment.systemPackages = with pkgs; [
          bridge-utils
          pciutils
          usbutils
          virt-manager
        ];
      }

      (lib.mkIf cfg.gpuPassthrough {
        boot.kernelParams = [
          "amd_iommu=on"
          "iommu=pt"
          "vfio-pci.ids=${hardware.gpu.pci}"
        ];

        boot.kernelModules = [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
        ];

        environment.etc."libvirt/hooks/qemu" = {
          mode = "0755";
          text = /* bash */ ''
            #!/run/current-system/sw/bin/bash

            GUEST_NAME="$1"
            OPERATION="$2"
            SUB_OPERATION="$3"

            GPU_CONTROLLER="${hardware.gpu.controller}"

            TARGET_VM="vm-app"

            if [ "$GUEST_NAME" == "$TARGET_VM" ]; then
              if [ "$OPERATION" == "release" ] || [ "$OPERATION" == "stopped" ]; then
                if [ -e "/sys/bus/pci/devices/$GPU_CONTROLLER/remove" ]; then
                    echo 1 > /sys/bus/pci/devices/$GPU_CONTROLLER/remove
                fi
                sleep 1
                echo 1 > /sys/bus/pci/rescan
                sleep 1
                echo "libvirt-qemu-hook: Executed PCIe rescan for AMD APU after $TARGET_VM shutdown." | systemd-cat -t libvirt-qemu-hook
              fi
            fi
          '';
        };
      })
    ]
  );
}
