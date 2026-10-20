{
  lib,
  config,
  consts,
  ...
}:
let
  inherit (consts) addresses ports;
  cfg = config.custom.services.security.crowdsec;
in
{
  options.custom.services.security.crowdsec = with lib; {
    enable = mkEnableOption "Enable CrowdSec agent";
    isBouncer = mkEnableOption "Enable nftables bouncer on this host";
    isServer = mkEnableOption "Enable the LAPI server on this host";
    serverAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "CrowdSec LAPI server address.";
    };
    bouncerApiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Runtime path to the CrowdSec bouncer API key, provisioned with agenix.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      (lib.optionals cfg.isBouncer [
        {
          assertion = cfg.serverAddress != null;
          message = "CrowdSec bouncer requires serverAddress.";
        }
        {
          assertion = cfg.serverAddress != "";
          message = "CrowdSec bouncer serverAddress must not be empty.";
        }
        {
          assertion = cfg.bouncerApiKeyFile != null;
          message = "CrowdSec bouncer requires bouncerApiKeyFile.";
        }
      ])
      ++ [
        {
          assertion = cfg.serverAddress == null || cfg.serverAddress != "";
          message = "CrowdSec serverAddress must not be empty when set.";
        }
      ];

    services = {
      crowdsec = {
        enable = true;
        extraGroups = [
          "systemd-journal"
        ]
        ++ lib.optional config.custom.services.networking.nginx.enable "nginx";

        hub.collections = [
          "crowdsecurity/linux"
        ]
        ++ lib.optional config.custom.services.networking.nginx.enable "crowdsecurity/nginx"
        ++ lib.optional config.custom.services.apps.development.forgejo.enable "crowdsecurity/gitea"
        ++ lib.optional config.custom.services.apps.tools.homeassistant.enable "crowdsecurity/home-assistant";

        settings = {
          acquisitions =
            (lib.optional config.services.openssh.enable {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
              labels.type = "syslog";
            })
            ++ (lib.optional config.custom.services.networking.nginx.enable {
              source = "file";
              filenames = [
                "/var/log/nginx/access.log"
                "/var/log/nginx/error.log"
              ];
              labels.type = "nginx";
            })
            ++ (lib.optional config.custom.services.apps.development.forgejo.enable {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=podman-forgejo-server.service" ];
              labels.type = "gitea";
            })
            ++ (lib.optional config.custom.services.apps.tools.homeassistant.enable {
              source = "file";
              filenames = [ "/var/lib/home-assistant/home-assistant.log" ];
              labels.type = "home-assistant";
            });

          config.api.server = {
            # enable = cfg.isServer;
            listen_uri = "${addresses.any}:${toString ports.crowdsec.lapi}";
          };
        };
      };

      crowdsec-firewall-bouncer = lib.mkIf cfg.isBouncer {
        enable = true;
        registerBouncer.enable = false;
        secrets.apiKeyPath = cfg.bouncerApiKeyFile;
        settings.api_url = "http://${cfg.serverAddress}:${toString ports.crowdsec.lapi}";
      };
    };
  };
}
