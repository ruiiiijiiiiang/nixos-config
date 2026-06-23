{
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts)
    addresses
    domain
    subdomains
    ports
    oci-uids
    ;
  inherit (helpers) mkOciUser mkVirtualHost;
  cfg = config.custom.services.apps.ai.zeroclaw;
  fqdn = "${subdomains.${config.networking.hostName}.zeroclaw}.${domain}";
in
{
  options.custom.services.apps.ai.zeroclaw = with lib; {
    enable = mkEnableOption "Enable ZeroClaw Personal AI Assistant";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      zeroclaw = {
        image = "ghcr.io/zeroclaw-labs/zeroclaw:latest";
        user = "${toString oci-uids.zeroclaw}:${toString oci-uids.zeroclaw}";
        ports = [ "${addresses.localhost}:${toString ports.zeroclaw}:${toString ports.zeroclaw}" ];
        environment = {
          ZEROCLAW_gateway__host = "0.0.0.0";
          ZEROCLAW_gateway__port = "42617";
          ZEROCLAW_gateway__allow_public_bind = "true";
        };
        volumes = [ "/var/lib/zeroclaw:/zeroclaw-data" ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "zeroclaw";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/zeroclaw 0700 ${toString oci-uids.zeroclaw} ${toString oci-uids.zeroclaw} - -"
      ];
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.zeroclaw;
      };
    };
  };
}
