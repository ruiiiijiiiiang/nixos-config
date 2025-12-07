{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rui.website;
  consts = import ../../lib/consts.nix;
  website = inputs.website.packages.${pkgs.stdenv.system}.default;
in
with consts;
{
  config = mkIf cfg.enable {
    systemd.services.personal-website = {
      description = "My Personal Website";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${website}/bin/server";
        WorkingDirectory = "${website}/share/website";
        DynamicUser = true;
        Restart = "always";
        RestartSec = "5s";
        Environment = [
          "IP=0.0.0.0"
          "PORT=${toString ports.website}"
        ];
      };
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
