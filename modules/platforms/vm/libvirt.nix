{ lib, ... }:
{
  options.custom.platforms.vm.libvirt = with lib; {
    enable = mkEnableOption "Guest VM managed by libvirt";
    cpu = mkOption {
      type = types.int;
      default = 4;
      description = "Number of vCPU's";
    };
    memory = mkOption {
      type = types.int;
      default = 4;
      description = "Amount of memory (unit in GiB)";
    };
    autoStart = mkEnableOption "Start the VM automatically";
    extraConfigs = mkOption {
      type = types.attrs;
      default = { };
      description = "Declarations directly merged into NixVirt";
    };
  };
}
