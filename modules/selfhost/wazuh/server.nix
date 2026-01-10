{
  config,
  consts,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    ;
  inherit (helpers) mkVirtualHost ensureFile;
  cfg = config.custom.selfhost.wazuh.server;
  fqdn = "${subdomains.${config.networking.hostName}.wazuh}.${domains.home}";
  dashboardsContent = import ./opensearch_dashboards.yml.nix;
  initialFile = pkgs.writeText "opensearch_dashboards.yml" dashboardsContent;
  dashboardsFile = "/var/wazuh/opensearch_dashboards.yml";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      wazuh-env.file = ../../../secrets/wazuh-env.age;
      # INDEXER_USERNAME
      # INDEXER_PASSWORD
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
        networks = [ "container:wazuh-indexer" ];
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
        networks = [ "container:wazuh-indexer" ];
      };
    };

    services.nginx.virtualHosts."${fqdn}" = mkVirtualHost {
      inherit fqdn;
      port = ports.wazuh.dashboard;
      extraConfig = ''
        auth_request_set $email  $upstream_http_x_email;
        proxy_set_header X-Email $email;
      '';
    };

    networking.firewall.allowedTCPPorts = [
      ports.wazuh.agent.connection
      ports.wazuh.agent.enrollment
    ];

    system.activationScripts.wazuh-dashboard-init = ''
      ${ensureFile {
        source = initialFile;
        destination = dashboardsFile;
      }}
    '';
    # sudo podman exec -u 0 -it wazuh-indexer env JAVA_HOME=/usr/share/wazuh-indexer/jdk bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh   -cd /usr/share/wazuh-indexer/config/opensearch-security   -icl   -nhnv   -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem   -cert /usr/share/wazuh-indexer/config/certs/admin.pem   -key /usr/share/wazuh-indexer/config/certs/admin-key.pem
  };
}
