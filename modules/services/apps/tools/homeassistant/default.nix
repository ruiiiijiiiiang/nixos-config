{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    timeZone
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.homeassistant;
  ha-fqdn = "${subdomains.${config.networking.hostName}.homeassistant}.${domains.home}";
  zwave-fqdn = "${subdomains.${config.networking.hostName}.zwave}.${domains.home}";
in
{
  options.custom.services.apps.tools.homeassistant = with lib; {
    enable = mkEnableOption "Home Assistant with Z-Wave server";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        ports = [
          "${
            addresses.infra.hosts.${config.networking.hostName}
          }:${toString ports.homeassistant}:${toString ports.homeassistant}"
          "${addresses.localhost}:${toString ports.homeassistant}:${toString ports.homeassistant}"
          "${addresses.localhost}:${toString ports.zwave}:${toString ports.zwave}"
        ];
        volumes = [ "/var/lib/home-assistant:/config" ];
        environment.TZ = timeZone;
        devices = [ "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0:/dev/zigbee" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      zwave-js-ui = {
        image = "docker.io/zwavejs/zwave-js-ui:latest";
        dependsOn = [ "homeassistant" ];
        volumes = [ "/var/lib/zwave-js-ui:/usr/src/app/store" ];
        networks = [ "container:homeassistant" ];
        devices = [
          "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_80edec297b57ed1193f12ef21c62bc44-if00-port0:/dev/zwave"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/home-assistant 0775 root wheel -"
        "d /var/lib/zwave-js-ui 0775 root wheel -"
      ];

      services.podman-homeassistant = mkNotifyService { };
    };

    services = {
      nginx.virtualHosts."${ha-fqdn}" = mkVirtualHost {
        fqdn = ha-fqdn;
        port = ports.homeassistant;
      };

      nginx.virtualHosts."${zwave-fqdn}" = mkVirtualHost {
        fqdn = zwave-fqdn;
        port = ports.zwave;
      };
    };
  };
}
