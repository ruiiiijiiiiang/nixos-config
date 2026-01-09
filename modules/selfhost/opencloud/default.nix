{
  config,
  consts,
  lib,
  pkgs,
  utilFns,
  ...
}:
let
  inherit (consts)
    addresses
    domains
    subdomains
    ports
    id-fqdn
    ;
  inherit (utilFns) mkVirtualHost;
  cfg = config.custom.selfhost.opencloud;
  opencloud-fqdn = "${subdomains.${config.networking.hostName}.opencloud}.${domains.home}";
  onlyoffice-fqdn = "${subdomains.${config.networking.hostName}.onlyoffice}.${domains.home}";
  cspTemplate = import ./csp.yaml.nix;
  cspContent =
    builtins.replaceStrings [ "@OFFICE_FQDN@" "@ID_FQDN@" ] [ onlyoffice-fqdn id-fqdn ]
      cspTemplate;
  initialFile = pkgs.writeText "csp.yaml" cspContent;
  cspFile = "/var/lib/opencloud/opencloud-config/csp.yaml";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = {
      opencloud-env.file = ../../../secrets/opencloud-env.age;
      # WEB_OIDC_CLIENT_ID
      # OC_JWT_SECRET
      # JWT_SECRET
    };

    virtualisation.oci-containers.containers = {
      opencloud = {
        image = "docker.io/opencloudeu/opencloud-rolling:latest";
        ports = [
          "${addresses.localhost}:${toString ports.opencloud}:9200"
          "${addresses.localhost}:${toString ports.onlyoffice}:80"
        ];
        volumes = [
          "/var/lib/opencloud/opencloud-config:/etc/opencloud"
          "/var/lib/opencloud/opencloud-data:/var/lib/opencloud"
        ];
        environment = {
          PROXY_TLS = "false";
          PROXY_HTTP_ADDR = "${addresses.any}:9200";
          PROXY_CSP_CONFIG_FILE_LOCATION = "/etc/opencloud/csp.yaml";
          OC_URL = "https://${opencloud-fqdn}";
          OC_INSECURE = "true";

          OC_ADD_RUN_SERVICES = "collaboration";
          COLLABORATION_APP_ADDR = "https://${onlyoffice-fqdn}";
          COLLABORATION_WOPI_SRC = "http://localhost:9200";
          COLLABORATION_APP_NAME = "OnlyOffice";
          COLLABORATION_APP_PRODUCT = "OnlyOffice";
          COLLABORATION_APP_INSECURE = "true";

          OC_OIDC_ISSUER = "https://${id-fqdn}";
          OC_EXCLUDE_RUN_SERVICES = "idp";
          PROXY_OIDC_REWRITE_WELLKNOWN = "true";
          PROXY_USER_OIDC_CLAIM = "preferred_username";
          PROXY_USER_CS3_CLAIM = "username";
          PROXY_AUTOPROVISION_ACCOUNTS = "true";
          PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
          PROXY_ROLE_ASSIGNMENT_DRIVER = "default";
          GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";
          WEB_OIDC_METADATA_URL = "https://${id-fqdn}/.well-known/openid-configuration";
        };
        environmentFiles = [ config.age.secrets.opencloud-env.path ];
      };

      onlyoffice = {
        image = "docker.io/onlyoffice/documentserver:latest";
        dependsOn = [ "opencloud" ];
        networks = [ "container:opencloud" ];
        volumes = [
          "onlyoffice-data:/var/www/onlyoffice/Data"
          "onlyoffice-log:/var/log/onlyoffice"
          "onlyoffice-lib:/var/lib/onlyoffice"
          "onlyoffice-db:/var/lib/postgresql"
        ];
        environment = {
          JWT_ENABLED = "true";
          JWT_HEADER = "AuthorizationJwt";
          WOPI_ENABLED = "true";
          USE_UNAUTHORIZED_STORAGE = "true";
        };
        environmentFiles = [ config.age.secrets.opencloud-env.path ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/opencloud/opencloud-data 0700 1000 1000 -"
      "d /var/lib/opencloud/opencloud-config 0700 1000 1000 -"
    ];

    services.nginx.virtualHosts = {
      "${opencloud-fqdn}" = mkVirtualHost {
        fqdn = opencloud-fqdn;
        port = ports.opencloud;
        proxyWebsockets = true;
      };
      "${onlyoffice-fqdn}" = mkVirtualHost {
        fqdn = onlyoffice-fqdn;
        port = ports.onlyoffice;
        proxyWebsockets = true;
      };
    };

    system.activationScripts.opencloud-init = ''
      mkdir -p $(dirname ${cspFile})
      if [ ! -f ${cspFile} ]; then
        echo "Initializing ${cspFile} ..."
        cat ${initialFile} > ${cspFile}
        chmod 644 ${cspFile}
      else
        echo "${cspFile} already exists. Skipping initialization."
      fi
    '';
  };
}
