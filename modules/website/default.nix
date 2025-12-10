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
      architecture = "aarch64";
      extraOptions = [ "--network=host" ];
      autoStart = true;
    };

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
