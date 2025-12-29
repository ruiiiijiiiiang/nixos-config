{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.wazuh.server;
  fqdn = "${consts.subdomains.${config.networking.hostName}.wazuh}.${consts.domains.home}";
  fileContent = import ./opensearch_dashboards.yml.nix;
  initialFile = pkgs.writeText "opensearch_dashboards.yml" fileContent;
  targetFile = "/var/wazuh/opensearch_dashboards.yml";
in
with consts;
{
  config = mkIf cfg.enable {
    age.secrets = {
      wazuh-env.file = ../../../secrets/wazuh-env.age;
    };

    virtualisation.oci-containers.containers = {
      wazuh-indexer = {
        image = "wazuh/wazuh-indexer:4.14.1";
        environment = {
          OPENSEARCH_JAVA_OPTS = "-Xms512m -Xmx512m";
        };
        ports = [
          "${toString ports.wazuh.agent.connection}:${toString ports.wazuh.agent.connection}"
          "${toString ports.wazuh.agent.enrollment}:${toString ports.wazuh.agent.enrollment}"
          "${addresses.localhost}:${toString ports.wazuh.dashboard}:${toString ports.wazuh.dashboard}"
        ];
        volumes = [
          "wazuh-indexer-data:/var/lib/wazuh-indexer"
          "/var/wazuh/certs/root-ca.pem:/usr/share/wazuh-indexer/config/certs/root-ca.pem"
          "/var/wazuh/certs/wazuh-indexer.pem:/usr/share/wazuh-indexer/config/certs/indexer.pem"
          "/var/wazuh/certs/wazuh-indexer-key.pem:/usr/share/wazuh-indexer/config/certs/indexer-key.pem"
          "/var/wazuh/certs/admin.pem:/usr/share/wazuh-indexer/config/certs/admin.pem"
          "/var/wazuh/certs/admin-key.pem:/usr/share/wazuh-indexer/config/certs/admin-key.pem"
        ];
        extraOptions = [
          "--ulimit=memlock=-1:-1"
          "--ulimit=nofile=65535:65535"
        ];
      };

      wazuh-manager = {
        image = "wazuh/wazuh-manager:4.14.1";
        environment = {
          INDEXER_URL = "https://${addresses.localhost}";
          FILEBEAT_SSL_VERIFICATION_MODE = "certificate";
          SSL_CERTIFICATE_AUTHORITIES = "/etc/ssl/wazuh_certs/root-ca.pem";
          SSL_CERTIFICATE = "/etc/ssl/wazuh_certs/wazuh-manager.pem";
          SSL_KEY = "/etc/ssl/wazuh_certs/wazuh-manager-key.pem";
        };
        environmentFiles = [ config.age.secrets.wazuh-env.path ];
        volumes = [
          "wazuh-api-configuration:/var/ossec/api/configuration"
          "wazuh-etc:/var/ossec/etc"
          "wazuh-logs:/var/ossec/logs"
          "wazuh-queue:/var/ossec/queue"
          "wazuh_var_multigroups:/var/ossec/var/multigroups"
          "wazuh_active_response:/var/ossec/active-response/bin"
          "wazuh_wodles:/var/ossec/wodles"
          "/var/wazuh/certs/root-ca.pem:/etc/ssl/wazuh_certs/root-ca.pem"
          "/var/wazuh/certs/wazuh-manager.pem:/etc/ssl/wazuh_certs/wazuh-manager.pem"
          "/var/wazuh/certs/wazuh-manager-key.pem:/etc/ssl/wazuh_certs/wazuh-manager-key.pem"
        ];
        dependsOn = [ "wazuh-indexer" ];
        extraOptions = [ "--network=container:wazuh-indexer" ];
      };

      wazuh-dashboard = {
        image = "wazuh/wazuh-dashboard:4.14.1";
        environment = {
          INDEXER_URL = "https://${addresses.localhost}";
          WAZUH_API_URL = "https://${addresses.localhost}";
          SERVER_HOST = addresses.any;
        };
        environmentFiles = [ config.age.secrets.wazuh-env.path ];
        volumes = [
          "wazuh-dashboard-config:/usr/share/wazuh-dashboard/config"
          "wazuh-dashboard-custom:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom"
          "/var/wazuh/certs/root-ca.pem:/usr/share/wazuh-dashboard/config/certs/root-ca.pem"
          "/var/wazuh/certs/wazuh-dashboard.pem:/usr/share/wazuh-dashboard/config/certs/dashboard.pem"
          "/var/wazuh/certs/wazuh-dashboard-key.pem:/usr/share/wazuh-dashboard/config/certs/dashboard-key.pem"
          "/var/wazuh/opensearch_dashboards.yml:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml"
        ];
        dependsOn = [
          "wazuh-indexer"
          "wazuh-manager"
        ];
        extraOptions = [ "--network=container:wazuh-indexer" ];
      };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = {
        useACMEHost = fqdn;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${addresses.localhost}:${toString ports.wazuh.dashboard}";
          proxyWebsockets = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      ports.wazuh.agent.connection
      ports.wazuh.agent.enrollment
    ];

    system.activationScripts.wazuh-dashboard-init = ''
      mkdir -p $(dirname ${targetFile})
      if [ ! -f ${targetFile} ]; then
        echo "Initializing ${targetFile} ..."
        cat ${initialFile} > ${targetFile}
        chmod 640 ${targetFile}
      else
        echo "${targetFile} already exists. Skipping initialization."
      fi
    '';
  };
}
