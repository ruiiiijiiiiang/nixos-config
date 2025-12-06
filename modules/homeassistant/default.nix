{ config, lib, ... }:
with lib;
let
  consts = import ../../lib/consts.nix;
  cfg = config.rui.homeassistant;
in
with consts;
{
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        volumes = [ "/var/lib/home-assistant:/config" ];
        environment.TZ = timeZone;
        extraOptions = [ "--network=host" ];
      };

      zwave-js-ui = {
        image = "zwavejs/zwave-js-ui:latest";
        volumes = [ "/var/lib/zwave-js-ui:/usr/src/app/store" ];
        extraOptions = [
          "--network=host"
          "--device=/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_80edec297b57ed1193f12ef21c62bc44-if00-port0:/dev/zwave"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/home-assistant 0755 root root -"
      "d /var/lib/zwave-js-ui 0755 root root -"
    ];

    services = {
      nginx.virtualHosts."ha.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.homeassistant}";
          proxyWebsockets = true;
        };
      };

      nginx.virtualHosts."zwave.${domains.home}" = {
        useACMEHost = domains.home;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.zwave.server}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
