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
  cfg = config.custom.services.observability.cockpit;
  fqdn = "${subdomains.${config.networking.hostName}.cockpit}.${domain}";
in
{
  options.custom.services.observability.cockpit = with lib; {
    enable = mkEnableOption "Enable Cockpit web management";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.roles.headless.hypervisor.libvirt.enable;
        message = "Cockpit requires the hypervisor libvirt role.";
      }
    ];

    services = {
      cockpit = {
        enable = true;
        port = ports.cockpit;
        settings = {
          WebService = {
            AllowUnencrypted = true;
            ProtocolHeader = "X-Forwarded-Proto";
          };
        };
        allowed-origins = [ "https://${fqdn}" ];
        showBanner = false;
        plugins = with pkgs; [
          cockpit-files
          cockpit-machines
        ];
      };

      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.cockpit;
      };
    };
  };
}
