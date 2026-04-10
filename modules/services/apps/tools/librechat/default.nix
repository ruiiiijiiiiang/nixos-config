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
    endpoints
    ;
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.librechat;
  fqdn = "${subdomains.${config.networking.hostName}.librechat}.${domain}";
in
{
  options.custom.services.apps.tools.librechat = with lib; {
    enable = mkEnableOption "Enable LibreChat";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      librechat-env.file = ../../../../../secrets/librechat-env.age;
      # POSTGRES_DB
      # POSTGRES_USER
      # POSTGRES_PASSWORD
      # MEILI_MASTER_KEY
      # GEMINI_API_KEY
      # JWT_SECRET
      # JWT_REFRESH_SECRET
      # OPENID_CLIENT_ID
      # OPENID_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers = {
      librechat-mongodb = {
        image = "docker.io/library/mongo:7.0.31";
        user = "${toString oci-uids.librechat}:${toString oci-uids.librechat}";
        ports = [ "${addresses.localhost}:${toString ports.librechat}:${toString ports.librechat}" ];
        volumes = [ "/var/lib/librechat/mongodb:/data/db" ];
        cmd = [
          "mongod"
          "--noauth"
        ];
      };

      librechat-vectordb = {
        image = "docker.io/pgvector/pgvector:0.8.0-pg15-trixie";
        dependsOn = [ "librechat-mongodb" ];
        networks = [ "container:librechat-mongodb" ];
        volumes = [ "/var/lib/librechat/vectordb:/var/lib/postgresql/data" ];
        environmentFiles = [ config.age.secrets.librechat-env.path ];
      };

      librechat-rag = {
        image = "registry.librechat.ai/danny-avila/librechat-rag-api-dev-lite:latest";
        user = "${toString oci-uids.librechat}:${toString oci-uids.librechat}";
        dependsOn = [ "librechat-mongodb" ];
        networks = [ "container:librechat-mongodb" ];
        volumes = [
          "/var/lib/librechat/images:/app/client/public/images"
          "/var/lib/librechat/uploads:/app/uploads"
          "/var/lib/librechat/logs:/app/logs"
        ];
        environment = {
          DB_HOST = addresses.localhost;
          RAG_PORT = "8000";
        };
        environmentFiles = [ config.age.secrets.librechat-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      librechat-meilisearch = {
        image = "docker.io/getmeili/meilisearch:latest";
        user = "${toString oci-uids.librechat}:${toString oci-uids.librechat}";
        dependsOn = [ "librechat-mongodb" ];
        networks = [ "container:librechat-mongodb" ];
        environment = {
          MEILI_NO_ANALYTICS = "true";
        };
        environmentFiles = [ config.age.secrets.librechat-env.path ];
        extraOptions = [
          "--tmpfs=/meili_data:rw,mode=0777"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      librechat-api = {
        image = "registry.librechat.ai/danny-avila/librechat-dev:latest";
        user = "${toString oci-uids.librechat}:${toString oci-uids.librechat}";
        dependsOn = [ "librechat-mongodb" ];
        networks = [ "container:librechat-mongodb" ];
        volumes = [
          "/var/lib/librechat/images:/app/client/public/images"
          "/var/lib/librechat/uploads:/app/uploads"
          "/var/lib/librechat/logs:/app/logs"
        ];
        environment = {
          HOST = addresses.any;
          PORT = toString ports.librechat;
          NO_INDEX = "true";
          SEARCH = "true";

          MONGO_URI = "mongodb://${addresses.localhost}:27017/LibreChat";
          MEILI_HOST = "http://${addresses.localhost}:7700";
          RAG_PORT = "8000";
          RAG_API_URL = "http://${addresses.localhost}:8000";

          DOMAIN_CLIENT = "https://${fqdn}";
          DOMAIN_SERVER = "https://${fqdn}";

          ALLOW_EMAIL_LOGIN = "true";
          ALLOW_REGISTRATION = "true";
          ALLOW_SOCIAL_LOGIN = "true";

          OPENID_BUTTON_LABEL = "Pocket ID";
          OPENID_ISSUER = "https://${endpoints.oidc-issuer}";
          OPENID_SCOPE = "openid profile email";
          OPENID_CALLBACK_URL = "/oauth/openid/callback";

          GOOGLE_MODELS = "gemini-3.1-pro-preview,gemini-3.1-pro-preview-customtools,gemini-3.1-flash-lite-preview,gemini-3-flash-preview,gemini-2.5-pro,gemini-2.5-flash,gemini-2.5-flash-lite";
        };
        environmentFiles = [ config.age.secrets.librechat-env.path ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = mkOciUser "librechat";

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/librechat/vectordb 0700 ${toString oci-uids.postgres} ${toString oci-uids.postgres} - -"
        "d /var/lib/librechat/mongodb 0700 ${toString oci-uids.librechat} ${toString oci-uids.librechat} - -"
        "d /var/lib/librechat/images 0700 ${toString oci-uids.librechat} ${toString oci-uids.librechat} - -"
        "d /var/lib/librechat/uploads 0700 ${toString oci-uids.librechat} ${toString oci-uids.librechat} - -"
        "d /var/lib/librechat/logs 0700 ${toString oci-uids.librechat} ${toString oci-uids.librechat} - -"
      ];

      services.podman-librechat-mongodb = mkNotifyService { };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.librechat;
      };
    };
  };
}
