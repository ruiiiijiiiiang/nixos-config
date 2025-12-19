{ config, lib, ... }:
with lib;
let
  cfg = config.selfhost.website;
  consts = import ../../../lib/consts.nix;
  fqdn = "${consts.subdomains.${config.networking.hostName}.public}.${consts.domains.home}";
in
with consts;
{
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.website = {
      image = "ghcr.io/ruiiiijiiiiang/website:latest";
      ports = [ "${toString ports.website}:${toString ports.website}" ];
      volumes = [ "/var/lib/blog:/app/blog:ro" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/blog 0775 root wheel -"
    ];

    services.nginx.virtualHosts."${fqdn}" = {
      useACMEHost = fqdn;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${addresses.localhost}:${toString ports.website}";
      };
      extraConfig = ''
        allow all;
        limit_req zone=website_req_limit burst=10 nodelay;
        limit_conn website_conn_limit 20;

        keepalive_timeout 10;
        send_timeout 10;
        server_tokens off;
      '';
    };
  };
}
