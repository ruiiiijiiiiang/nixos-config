{ consts, inputs, ... }:
let
  inherit (consts) addresses;
  lanInterface = "end0";
  wlanInterface = "wlan0";
  vlanId = 20;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  system.stateVersion = "25.05";
  networking.hostName = "pi";

  custom = {
    platform.pi = {
      hardware.enable = true;
      networking = {
        enable = true;
        inherit lanInterface wlanInterface vlanId;
      };
      packages.enable = true;
    };

    roles.headless = {
      networking.enable = true;
      security.enable = true;
      services.enable = true;
    };

    services = {
      networking.dns = {
        enable = true;
        interface = "${lanInterface}.${toString vlanId}";
        vrrp = {
          enable = true;
          state = "BACKUP";
          priority = 90;
        };
      };

      apps.tools.homeassistant.enable = true;

      networking.nginx.enable = true;

      security.fail2ban.enable = true;

      observability = {
        beszel.agent.enable = true;
        dockhand.agent.enable = true;
        loki.agent = {
          enable = true;
          serverAddress = addresses.infra.hosts.vm-monitor;
        };
        prometheus.exporters = {
          nginx.enable = true;
          node.enable = true;
          podman.enable = true;
        };
      };
    };
  };
}
