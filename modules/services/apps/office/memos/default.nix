{
  config,
  consts,
  lib,
  helpers,
  ...
}:
let
  inherit (consts)
    domain
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.apps.office.memos;
  fqdn = "${subdomains.${config.networking.hostName}.memos}.${domain}";
in
{
  options.custom.services.apps.office.memos = with lib; {
    enable = mkEnableOption "Enable Memos";
  };

  config = lib.mkIf cfg.enable {
    services.memos = {
      enable = true;
      settings = {
        MEMOS_MODE = "prod";
        MEMOS_ADDR = "127.0.0.1";
        MEMOS_PORT = toString ports.memos;
        MEMOS_DATA = config.services.memos.dataDir;
        MEMOS_DRIVER = "sqlite";
        MEMOS_INSTANCE_URL = "http://localhost:${toString ports.memos}";
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.memos;
    };
  };
}
