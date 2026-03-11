{
  config,
  consts,
  lib,
  ...
}:
let
  inherit (consts) username addresses oci-uids;
  cfg = config.custom.services.infra.podman;
in
{
  options.custom.services.infra.podman = with lib; {
    enable = mkEnableOption "Enable headless Podman role";
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = config.virtualisation.oci-containers.containers == { } || cfg.enable;
          message = "OCI containers are defined but custom.services.infra.podman.enable is false.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
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
    })
  ];
}
