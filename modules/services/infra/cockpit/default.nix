{
  config,
  consts,
  lib,
  helpers,
  pkgs,
  ...
}:
let
  inherit (consts) domain subdomains ports;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.infra.cockpit;
  fqdn = "${subdomains.${config.networking.hostName}.cockpit}.${domain}";
in
{
  options.custom.services.infra.cockpit = with lib; {
    enable = mkEnableOption "Cockpit web-based interface for managing servers";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.roles.hypervisor.libvirt.enable;
        message = "Cockpit can only be enabled on the hypervisor";
      }
    ];

    services.cockpit = {
      enable = true;
      port = ports.cockpit;
      settings = {
        WebService = {
          AllowUnencrypted = true;
          ProtocolHeader = "X-Forwarded-Proto";
          Origins = fqdn;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      cockpit-machines
      libvirt-dbus
    ];

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.cockpit;
      };
    };
  };
}
