{ consts, ... }:
let
  inherit (consts) addresses ports vlan-ids;
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
        extraConfigs = {
          devices = {
            graphics = [
              {
                type = "spice";
                autoport = false;
                port = ports.spice.vm-cyber;
                listen = {
                  type = "address";
                  address = addresses.any;
                };
              }
            ];
            channel = [
              {
                type = "spicevmc";
                target = {
                  type = "virtio";
                  name = "com.redhat.spice.0";
                };
              }
            ];
          };
        };
      };

      disks.enable = true;

      networking = {
        enable = true;
        lanInterface = "lan0";
      };
    };

    roles = {
      workstation = {
        catppuccin.enable = true;
        packages.enable = true;

        cyber = {
          networking.enable = true;
          packages.enable = true;
          security.enable = true;
          services.enable = true;
        };
      };
    };
  };
}
