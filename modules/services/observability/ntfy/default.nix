{
  config,
  consts,
  helpers,
  lib,
  secretsDir,
  ...
}:
let
  inherit (consts) addresses edge-observability ports;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.observability.ntfy;
in
{
  options.custom.services.observability.ntfy = {
    enable = lib.mkEnableOption "Enable ntfy";

    fqdn = lib.mkOption {
      type = lib.types.str;
      default = edge-observability.ntfy-server;
      description = "Externally advertised ntfy FQDN.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.ntfy-server-environment.file = secretsDir + "/observability/ntfy/server.env.age";

    custom.services.networking.nginx.additionalFqdns = [ cfg.fqdn ];

    services.ntfy-sh = {
      enable = true;
      environmentFile = config.age.secrets.ntfy-server-environment.path;
      settings = {
        base-url = "https://${cfg.fqdn}";
        behind-proxy = true;
        listen-http = "${addresses.localhost}:${toString ports.ntfy}";
        auth-file = "/var/lib/ntfy-sh/user.db";
        auth-default-access = "deny-all";
        cache-file = "/var/lib/ntfy-sh/cache-file.db";
        attachment-cache-dir = "";
        enable-login = true;
      };
    };

    services.nginx.virtualHosts."${cfg.fqdn}" = mkVirtualHost {
      fqdn = cfg.fqdn;
      port = ports.ntfy;
    };
  };
}
