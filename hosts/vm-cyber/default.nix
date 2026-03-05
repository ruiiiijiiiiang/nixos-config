{ consts, ... }:
let
  inherit (consts) vlan-ids;
  vlanId = vlan-ids.dmz;
in
{
  system.stateVersion = "25.11";
  networking.hostName = "vm-cyber";

  custom = {
    platforms.vm = {
      kernel = {
        enable = true;
        workstation = true;
      };

      libvirt = {
        enable = true;
        cpu = 4;
        memory = 4;
        inherit vlanId;
      };

      disks.enable = true;
    };

    roles = {
      workstation = {
        catppuccin.enable = true;
        packages.enable = true;

        cyber = {
          networking.enable = true;
          packages.enable = true;
          services.enable = true;
          security.enable = true;
        };
      };
    };
  };
}
