let
  wanInterface = "eno1";
  lanInterface = "enxc8a362bf0bb3";
in
{
  system.stateVersion = "25.11";
  networking.hostName = "hypervisor";

  custom = {
    platforms.minipc = {
      hardware = true;
    };

    roles = {
      networking = {
        enable = true;
        inherit wanInterface lanInterface;
      };
    };
  };
}
