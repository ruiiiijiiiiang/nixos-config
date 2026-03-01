{ lib, ... }:
{
  imports = [
    ./hardware.nix
    ./disks.nix
  ];

  options.custom.libvirtGuest = with lib; {
    enable = mkEnableOption "Guest VM managed by libvirt";
    config = mkOption {
      type = types.attrs;
      description = "Declarations used by libvirt to provision guest VM";
    };
    disks = {
      primary = {
        size = mkOption {
          type = types.str;
          default = "50GB";
          description = "Size of guest VM's primary disk";
        };
      };
      storage = {
        enable = mkEnableOption "Storage disk for guest VM";
        size = mkOption {
          type = types.str;
          default = "500GB";
          description = "Size of guest VM's storage disk";
        };
      };
      scratch = {
        enable = mkEnableOption "Scratch disk for guest VM";
        size = mkOption {
          type = types.str;
          default = "500GB";
          description = "Size of guest VM's scratch disk";
        };
      };
    };
    gpuPassthrough = mkEnableOption "Passthrough host's GPU to guest";
  };
}
