{
  config,
  consts,
  lib,
  helpers,
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
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.web.website;
  fqdn = "${subdomains.${config.networking.hostName}.public}.${domain}";
in
{
  options.custom.services.apps.web.website = with lib; {
    enable = mkEnableOption "Personal website hosting";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.website = {
      image = "git.ruijiang.me/rui/website:latest";
      user = "${toString oci-uids.user}:${toString oci-uids.user}";
      ports = [ "${addresses.localhost}:${toString ports.website}:${toString ports.website}" ];
      volumes = [ "/var/lib/blog:/app/blog:ro" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/blog 0775 root wheel -"
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
