{ lib, ... }:
{
  options.custom.platforms.vm.libvirt = with lib; {
    enable = mkEnableOption "Guest VM managed by libvirt";
    config = mkOption {
      type = types.attrs;
      description = "Declarations used by libvirt to provision guest VM";
    };
  };
}
