{ config, lib, ... }:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.homeassistant;
  haFqdn = "${consts.subdomains.${config.networking.hostName}.homeassistant}.${consts.domains.home}";
  zwaveFqdn = "${consts.subdomains.${config.networking.hostName}.zwave}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        ports = [
          "${toString ports.homeassistant}:${toString ports.homeassistant}"
          "${toString ports.zwave}:${toString ports.zwave}"
        ];
        volumes = [ "/var/lib/home-assistant:/config" ];
        environment.TZ = timeZone;
      };

      zwave-js-ui = {
        dependsOn = [ "homeassistant" ];
        image = "zwavejs/zwave-js-ui:latest";
        volumes = [ "/var/lib/zwave-js-ui:/usr/src/app/store" ];
        extraOptions = [
          "--network=container:homeassistant"
          "--device=/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_80edec297b57ed1193f12ef21c62bc44-if00-port0:/dev/zwave"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/home-assistant 0775 root wheel -"
      "d /var/lib/zwave-js-ui 0775 root wheel -"
    ];

    services = {
      nginx.virtualHosts."${haFqdn}" = {
        useACMEHost = haFqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.homeassistant}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };

      nginx.virtualHosts."${zwaveFqdn}" = {
        useACMEHost = zwaveFqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.zwave}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };
}
