{
  config,
  lib,
  pkgs,
  ...
}:
let
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
          "vfio-pci.ids=1002:1681"
        ];

        boot.kernelModules = [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
        ];
      })
    ]
  );
}
