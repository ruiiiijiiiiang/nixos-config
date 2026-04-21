{
  config,
  consts,
  lib,
  helpers,
  inputs,
  pkgs,
  ...
}:
let
  inherit (consts)
    domain
    subdomains
    ports
    username
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.web.website;
  fqdn = "${subdomains.${config.networking.hostName}.public}.${domain}";
in
{
  options.custom.services.apps.web.website = with lib; {
    enable = mkEnableOption "Enable website hosting";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.website = {
      description = "Website service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        rm -rf /var/lib/website/public
        mkdir -p /var/lib/website/public

        cp -f --no-preserve=mode ${
          inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/app/server /var/lib/website/server
        cp -f --no-preserve=mode ${
          inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/app/sitemap /var/lib/website/sitemap
        cp -rf --no-preserve=mode ${
          inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/app/public/. /var/lib/website/public/

        chmod +x /var/lib/website/server /var/lib/website/sitemap
        chmod -R u+w /var/lib/website

        /var/lib/website/sitemap
      '';
      serviceConfig = {
        ExecStart = "/var/lib/website/server";
        User = username;
        Restart = "always";
        Environment = [
          "PORT=${toString ports.website}"
        ];
        WorkingDirectory = "/var/lib/website";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/website 0775 ${username} wheel -"
    ];

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.website;
      extraConfig = /* nginx */ ''
        allow all;
        limit_req zone=website_req_limit burst=10 nodelay;
        limit_conn website_conn_limit 20;

        keepalive_timeout 10;
        send_timeout 10;
        server_tokens off;

        location ~* \.php$ { return 404; }
        location ~* ^/wp- { return 404; }
        location = /xmlrpc.php { return 404; }
      '';
    };
  };
}
