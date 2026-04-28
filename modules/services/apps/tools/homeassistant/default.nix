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
    domain
    subdomains
    ports
    hardware
    ;
  inherit (helpers) getHostAddress mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.homeassistant;
  ha-fqdn = "${subdomains.${config.networking.hostName}.homeassistant}.${domain}";
  zwave-fqdn = "${subdomains.${config.networking.hostName}.zwave}.${domain}";
in
{
  options.custom.services.apps.tools.homeassistant = with lib; {
    enable = mkEnableOption "Enable Home Assistant";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        ports = [
          "${getHostAddress config.networking.hostName}:${toString ports.homeassistant}:${toString ports.homeassistant}"
          "${addresses.localhost}:${toString ports.homeassistant}:${toString ports.homeassistant}"
          "${addresses.localhost}:${toString ports.zwave}:${toString ports.zwave}"
        ];
        volumes = [ "/var/lib/home-assistant:/config" ];
        environment.TZ = timeZone;
        devices = [ "/dev/serial/by-id/${hardware.radios.zigbee}:/dev/zigbee" ];
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
          "/dev/serial/by-id/${hardware.radios.zwave}:/dev/zwave"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      matter-server = {
        image = "ghcr.io/matter-js/python-matter-server:stable";
        dependsOn = [ "homeassistant" ];
        volumes = [ "/var/lib/matter-server:/data" ];
        networks = [ "host" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/home-assistant 0775 root wheel -"
        "d /var/lib/zwave-js-ui 0775 root wheel -"
        "d /var/lib/matter-server 0775 root wheel -"
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

    networking.firewall = {
      allowedTCPPorts = [ ports.matter ];
      allowedUDPPorts = [
        ports.mdns
        ports.matter
      ];
    };
  };
}
