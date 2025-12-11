{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rui.website;
  consts = import ../../lib/consts.nix;
in
with consts;
{
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.website = {
      image = "ghcr.io/ruiiiijiiiiang/website:latest";
      ports = [ "${toString ports.website}:${toString ports.website}" ];
      volumes = [ "/var/lib/blog:/app:ro" ];
      extraOptions = [ "--arch=arm64" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/blog 0775 root wheel -"
    ];

    services.nginx.virtualHosts."public.${domains.home}" = {
      useACMEHost = domains.home;
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

        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline';" always;
      '';
    };
  };
}
