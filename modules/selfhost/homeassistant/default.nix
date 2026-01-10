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
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.selfhost.homeassistant;
  ha-fqdn = "${subdomains.${config.networking.hostName}.homeassistant}.${domains.home}";
  zwave-fqdn = "${subdomains.${config.networking.hostName}.zwave}.${domains.home}";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        ports = [
          "${toString ports.homeassistant}:${toString ports.homeassistant}"
          "${addresses.localhost}:${toString ports.zwave}:${toString ports.zwave}"
        ];
        volumes = [ "/var/lib/home-assistant:/config" ];
        environment.TZ = timeZone;
        devices = [ "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      zwave-js-ui = {
        dependsOn = [ "homeassistant" ];
        image = "docker.io/zwavejs/zwave-js-ui:latest";
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

    systemd.tmpfiles.rules = [
      "d /var/lib/home-assistant 0775 root wheel -"
      "d /var/lib/zwave-js-ui 0775 root wheel -"
    ];

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
