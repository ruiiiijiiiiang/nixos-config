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
  credentials = config.age.secrets.wazuh-env.path;
  rootCA = config.age.secrets.wazuh-root-ca.path;
in
{
  options.custom.services.security.wazuh.server = {
    enable = lib.mkEnableOption "Wazuh server";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      wazuh-env = {
        file = secretsDir + "/security/wazuh/env.age";
        mode = "0400";
        # INDEXER_USERNAME
        # INDEXER_PASSWORD
        # DASHBOARD_USERNAME
        # DASHBOARD_PASSWORD
        # API_USERNAME
        # API_PASSWORD
        # API_ADMIN_USERNAME
        # API_ADMIN_PASSWORD
      };
      wazuh-root-ca = {
        file = secretsDir + "/security/wazuh/root-ca.age";
        mode = "0400";
      };
      wazuh-indexer-cert = {
        file = secretsDir + "/security/wazuh/indexer-cert.age";
        mode = "0400";
      };
      wazuh-indexer-key = {
        file = secretsDir + "/security/wazuh/indexer-key.age";
        mode = "0400";
      };
      wazuh-admin-cert = {
        file = secretsDir + "/security/wazuh/admin-cert.age";
        mode = "0400";
      };
      wazuh-admin-key = {
        file = secretsDir + "/security/wazuh/admin-key.age";
        mode = "0400";
      };
      wazuh-filebeat-cert = {
        file = secretsDir + "/security/wazuh/filebeat-cert.age";
        mode = "0400";
      };
      wazuh-filebeat-key = {
        file = secretsDir + "/security/wazuh/filebeat-key.age";
        mode = "0400";
      };
    };

    services.wazuh = {
      manager = {
        enable = true;
        environmentFile = credentials;
        eventPort = ports.wazuh.agent.connection;
        enrollmentPort = ports.wazuh.agent.enrollment;
        apiPort = ports.wazuh.manager;
      };

      filebeat = {
        enable = true;
        environmentFile = credentials;
        indexerUrl = "https://127.0.0.1:${toString ports.wazuh.indexer}";
        certificates = {
          inherit rootCA;
          certificate = config.age.secrets.wazuh-filebeat-cert.path;
          key = config.age.secrets.wazuh-filebeat-key.path;
        };
      };

      indexer = {
        enable = true;
        port = ports.wazuh.indexer;
        certificates = {
          inherit rootCA;
          nodeCertificate = config.age.secrets.wazuh-indexer-cert.path;
          nodeKey = config.age.secrets.wazuh-indexer-key.path;
          adminCertificate = config.age.secrets.wazuh-admin-cert.path;
          adminKey = config.age.secrets.wazuh-admin-key.path;
        };
        securityBootstrap = {
          enable = true;
          environmentFile = credentials;
        };
      };

      dashboard = {
        enable = true;
        environmentFile = credentials;
        port = ports.wazuh.dashboard;
        indexerUrl = "https://127.0.0.1:${toString ports.wazuh.indexer}";
        managerApiPort = ports.wazuh.manager;
        certificates = {
          inherit rootCA;
        };
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
  };
}
