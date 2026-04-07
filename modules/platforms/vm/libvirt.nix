{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) vlan-ids;
  cfg = config.custom.platforms.vm.libvirt;
in
{
  options.custom.platforms.vm.libvirt = with lib; {
    enable = mkEnableOption "Enable libvirt settings for a guest VM";
    cpu = mkOption {
      type = types.ints.positive;
      default = 4;
      description = "vCPU count.";
    };
    memory = mkOption {
      type = types.ints.positive;
      default = 4;
      description = "Memory in GiB.";
    };
    vlanId = mkOption {
      type = types.ints.positive;
      default = vlan-ids.infra;
      description = "VLAN ID for the guest NIC.";
    };
    autoStart = mkEnableOption "Start the VM automatically";
    extraConfigs = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra NixVirt domain attributes to merge.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.elem cfg.vlanId (lib.attrValues vlan-ids);
        message = "VM libvirt VLAN ID must exist in consts.vlan-ids.";
      }
    ];
  };
}
