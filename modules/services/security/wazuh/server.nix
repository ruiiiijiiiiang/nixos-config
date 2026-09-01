{
  secretsDir,
  config,
  consts,
  helpers,
  lib,
  ...
}:
let
  inherit (consts) domain subdomains ports;
  inherit (helpers) mkVirtualHost;
  cfg = config.custom.services.security.wazuh.server;
  fqdn = "${subdomains.${config.networking.hostName}.wazuh}.${domain}";
in
{
  options.custom.services.security.wazuh.server = {
    enable = lib.mkEnableOption "Wazuh server";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      wazuh-dashboard-admin-password = {
        file = secretsDir + "/security/wazuh/dashboard-admin-password.age";
        mode = "0400";
      };
    };

    services.wazuh = {
      certificates.autoProvision.enable = true;
      credentials.autoProvision = {
        enable = true;
        indexerPasswordFile = config.age.secrets.wazuh-dashboard-admin-password.path;
      };

      manager = {
        enable = true;
        eventPort = ports.wazuh.agent.connection;
        enrollmentPort = ports.wazuh.agent.enrollment;
        apiPort = ports.wazuh.manager;
      };

      filebeat = {
        enable = true;
        indexerUrl = "https://127.0.0.1:${toString ports.wazuh.indexer}";
      };

      indexer = {
        enable = true;
        port = ports.wazuh.indexer;
        securityBootstrap = {
          enable = true;
        };
      };

      dashboard = {
        enable = true;
        port = ports.wazuh.dashboard;
        indexerUrl = "https://127.0.0.1:${toString ports.wazuh.indexer}";
        managerApiPort = ports.wazuh.manager;
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.wazuh.dashboard;
      extraConfig = ''
        auth_request_set $email $upstream_http_x_email;
        proxy_set_header X-Email $email;
      '';
    };

    custom.services.infra.restic = {
      localPaths = [ "/var/ossec/etc" ];
      remotePaths = [ "/var/ossec/etc" ];
    };
  };
}
