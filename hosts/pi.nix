{ consts, helpers, inputs, ... }:
let
  inherit (consts) vlan-ids;
  inherit (helpers) getHostAddress;
  hostName = "pi";
  lanInterface = "end0";
  wlanInterface = "wlan0";
  vlanId = vlan-ids.infra;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  system.stateVersion = "25.05";
  networking.hostName = hostName;

  custom = {
    platforms.pi = {
      kernel.enable = true;
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

      infra = {
        nfs.server = {
          enable = true;
          interfaces = [ "${lanInterface}.${toString vlanId}" ];
        };
        podman = {
          enable = true;
          autoUpdate.enable = true;
        };
      };

      networking.nginx.enable = true;

      security.fail2ban.enable = true;

      observability = {
        beszel.agent.enable = true;
        dockhand.agent.enable = true;
        loki.agent = {
          enable = true;
          serverAddress = getHostAddress "vm-monitor";
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
