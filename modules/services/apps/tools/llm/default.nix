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
    domains
    subdomains
    ports
    oci-uids
    oidc-issuer
    ;
  inherit (helpers) mkOciUser mkVirtualHost mkNotifyService;
  cfg = config.custom.services.apps.tools.llm;
  fqdn = "${subdomains.${config.networking.hostName}.openwebui}.${domains.home}";
in
{
  options.custom.services.apps.tools.llm = with lib; {
    enable = mkEnableOption "Large language model";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      openwebui-env.file = ../../../../../secrets/openwebui-env.age;
      # WEBUI_SECRET_KEY
      # OAUTH_CLIENT_ID
      # OAUTH_CLIENT_SECRET
    };

    virtualisation.oci-containers.containers = {
      ollama = {
        image = "docker.io/ollama/ollama:rocm";
        user = "${toString oci-uids.llm}:${toString oci-uids.llm}";
        ports = [
          "${addresses.localhost}:${toString ports.ollama}:${toString ports.ollama}"
          "${addresses.localhost}:${toString ports.openwebui}:${toString ports.openwebui}"
        ];
        environment = {
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
          OLLAMA_HOST = addresses.any;
          HOME = "/var/lib/ollama";
        };
        volumes = [
          "/var/lib/ollama:/var/lib/ollama"
          "/dev/kfd:/dev/kfd:ro"
          "/dev/dri:/dev/dri:ro"
        ];
        devices = [
          "/dev/kfd:/dev/kfd"
          "/dev/dri:/dev/dri"
        ]
        ++ lib.optional config.custom.platform.vm.hardware.gpuPassthrough "/dev/dri/renderD128:/dev/dri/renderD128";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };

      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        user = "${toString oci-uids.llm}:${toString oci-uids.llm}";
        dependsOn = [ "ollama" ];
        networks = [ "container:ollama" ];
        environment = {
          OLLAMA_BASE_URL = "http://${addresses.localhost}:${toString ports.ollama}";
          PORT = toString ports.openwebui;
          WEBUI_URL = "https://${fqdn}";
          ENABLE_OAUTH_PERSISTENT_CONFIG = "false";
          ENABLE_OAUTH_SIGNUP = "true";
          OPENID_PROVIDER_URL = "https://${oidc-issuer}/.well-known/openid-configuration";
          OAUTH_PROVIDER_NAME = "Pocket ID";
          OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
        };
        environmentFiles = [ config.age.secrets.openwebui-env.path ];
        volumes = [
          "/var/lib/open-webui:/app/backend/data"
        ];
        labels = {
          "io.containers.autoupdate" = "registry";
        };
      };
    };

    users = lib.mkMerge [
      (mkOciUser "llm")
      {
        users.llm.extraGroups = [
          "video"
          "render"
        ];
      }
    ];

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/ollama 0700 ${toString oci-uids.llm} ${toString oci-uids.llm} - -"
        "d /var/lib/open-webui 0700 ${toString oci-uids.llm} ${toString oci-uids.llm} - -"
      ];

      services.podman-ollama = mkNotifyService { };
    };

    services = {
      nginx.virtualHosts."${fqdn}" = mkVirtualHost {
        inherit fqdn;
        port = ports.openwebui;
      };
    };
  };
}
