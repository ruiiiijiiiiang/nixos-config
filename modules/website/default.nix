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
      extraOptions = [ "--arch=arm64" "--network=host" ];
      volumes = [
        "/var/lib/blog:/var/lib/blog:ro"
      ];
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
        limit_req zone=website_limit burst=10 nodelay;
      '';
    };
  };
}
