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
    oidc-issuer
    oci-uids
    ;
  inherit (helpers)
    ensureFile
    mkOciUser
    mkVirtualHost
    mkNotifyService
    ;
  cfg = config.custom.services.apps.office.opencloud;
  opencloud-fqdn = "${subdomains.${config.networking.hostName}.opencloud}.${domains.home}";
  onlyoffice-fqdn = "${subdomains.${config.networking.hostName}.onlyoffice}.${domains.home}";
  cspTemplate = import ./csp.yaml.nix;
  cspContent =
    builtins.replaceStrings [ "@OFFICE_FQDN@" "@ID_FQDN@" ] [ onlyoffice-fqdn oidc-issuer ]
      cspTemplate;
  initialFile = pkgs.writeText "csp.yaml" cspContent;
  cspFile = "/var/lib/opencloud/config/csp.yaml";
  opencloud-port = "9200";
in
{
  options.custom.services.apps.office.opencloud = with lib; {
    enable = mkEnableOption "OpenCloud file server";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      opencloud-env.file = ../../../../../secrets/opencloud-env.age;
      # WEB_OIDC_CLIENT_ID
      # OC_JWT_SECRET
      # JWT_SECRET
    };

    virtualisation.oci-containers.containers = {
      opencloud = {
        image = "docker.io/opencloudeu/opencloud-rolling:latest";
        user = "${toString oci-uids.opencloud}:${toString oci-uids.opencloud}";
        ports = [
          "${addresses.localhost}:${toString ports.opencloud}:${opencloud-port}"
          "${addresses.localhost}:${toString ports.onlyoffice}:80"
        ];
        volumes = [
          "/var/lib/opencloud/config:/etc/opencloud"
          "/var/storage/opencloud:/var/lib/opencloud"
        ];
        environment = {
          PROXY_TLS = "false";
          PROXY_HTTP_ADDR = "${addresses.any}:${opencloud-port}";
          PROXY_CSP_CONFIG_FILE_LOCATION = "/etc/opencloud/csp.yaml";
          OC_URL = "https://${opencloud-fqdn}";
          OC_INSECURE = "true";

          OC_ADD_RUN_SERVICES = "collaboration";
          COLLABORATION_APP_ADDR = "https://${onlyoffice-fqdn}";
          COLLABORATION_WOPI_SRC = "http://localhost:${opencloud-port}";
          COLLABORATION_APP_NAME = "OnlyOffice";
          COLLABORATION_APP_PRODUCT = "OnlyOffice";
          COLLABORATION_APP_INSECURE = "true";

          OC_OIDC_ISSUER = "https://${oidc-issuer}";
          OC_EXCLUDE_RUN_SERVICES = "idp";
          PROXY_OIDC_REWRITE_WELLKNOWN = "true";
          PROXY_USER_OIDC_CLAIM = "preferred_username";
          PROXY_USER_CS3_CLAIM = "username";
          PROXY_AUTOPROVISION_ACCOUNTS = "true";
          PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
          PROXY_ROLE_ASSIGNMENT_DRIVER = "default";
          GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";
          WEB_OIDC_METADATA_URL = "https://${oidc-issuer}/.well-known/openid-configuration";
        };
        environmentFiles = [ config.age.secrets.opencloud-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
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
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "opencloud";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/opencloud/config 0755 ${toString oci-uids.opencloud} ${toString oci-uids.opencloud} - -"
        "d /var/storage/opencloud 0755 ${toString oci-uids.opencloud} ${toString oci-uids.opencloud} - -"
      ];

      services.podman-opencloud = mkNotifyService { timeout = 600; };
    };

    services.nginx.virtualHosts = {
      "${opencloud-fqdn}" = mkVirtualHost {
        fqdn = opencloud-fqdn;
        port = ports.opencloud;
      };
      "${onlyoffice-fqdn}" = mkVirtualHost {
        fqdn = onlyoffice-fqdn;
        port = ports.onlyoffice;
      };
    };

    system.activationScripts.opencloud-init = ''
      ${ensureFile {
        source = initialFile;
        destination = cspFile;
        mode = "644";
      }}
    '';
  };
}
