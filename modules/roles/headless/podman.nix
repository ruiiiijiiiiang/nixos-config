{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) username addresses oci-uids;
  cfg = config.custom.roles.headless.podman;
in
{
  options.custom.roles.headless.podman = with lib; {
    enable = mkEnableOption "Enable headless Podman role";
  };

  assertions = [
    {
      assertion = config.virtualisation.oci-containers.containers == { } || cfg.enable;
      message = "OCI containers are defined but custom.roles.headless.podman.enable is false.";
    }
  ];

  config = lib.mkIf cfg.enable {
    virtualisation = {
      containers.containersConf.settings = {
        containers = {
          dns_servers = [
            addresses.infra.vip.dns
          ];
        };
      };
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
        defaultNetwork.settings = {
          dns_enable = true;
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
