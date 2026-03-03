{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) username oci-uids;
  cfg = config.custom.roles.headless.podman;
in
{
  options.custom.roles.headless.podman = with lib; {
    enable = mkEnableOption "Custom podman for headless instances";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      oci-containers = {
        backend = "podman";
      };
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };
      };
    };

    users = {
      users.${username}.extraGroups = [
        "podman"
      ];
      groups.podman.gid = oci-uids.podman;
    };

    systemd.timers.podman-auto-update = {
      wantedBy = [ "timers.target" ];
      enable = true;
    };
  };
}
