{ consts, ... }:
let
  inherit (consts) vlan-ids;
  wanInterface = "eno1";
  lanInterface = "enxc8a362bf0bb3";
  wanBridge = "vmbr0";
  lanBridge = "vmbr1";
in
{
  system.stateVersion = "25.11";
  networking.hostName = "hypervisor";

  custom = {
    platforms.minipc = {
      hardware = true;
    };

    roles.hypervisor = {
      networking = {
        enable = true;
        inherit
          wanInterface
          lanInterface
          wanBridge
          lanBridge
          ;
        vlanId = vlan-ids.infra;
      };
      provisioning = {
        enable = true;
        inherit lanBridge;
      };
    };
  };
}
