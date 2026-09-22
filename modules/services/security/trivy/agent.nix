{
  config,
  consts,
  helpers,
  inputs,
  lib,
  pkgs,
  secretsDir,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (consts)
    endpoints
    ntfy-topics
    ports
    task-schedules
    ;
  inherit (helpers) getHostAddress anyHostEnabled;
  inherit (inputs.self) nixosConfigurations;
  cfg = config.custom.services.security.trivy.scanning;
  ntfyEnabled = anyHostEnabled nixosConfigurations [
    "custom"
    "services"
    "observability"
    "ntfy"
    "enable"
  ];
  scriptText =
    lib.replaceStrings
      [
        "@SERVER_ADDR@"
        "@SCANNERS@"
        "@NTFY_SERVER@"
        "@NTFY_ENABLED@"
        "@NTFY_TOPIC@"
        "@HOST_NAME@"
      ]
      [
        (lib.escapeShellArg "${cfg.serverAddress}:${toString ports.trivy}")
        (lib.escapeShellArg (builtins.concatStringsSep "," cfg.scanners))
        (lib.escapeShellArg endpoints.ntfy-server)
        (lib.escapeShellArg (lib.boolToString ntfyEnabled))
        (lib.escapeShellArg ntfy-topics.trivy)
        (lib.escapeShellArg hostName)
      ]
      (lib.readFile ./trivy-scan.sh);

  scanScript = pkgs.writeShellApplication {
    name = "trivy-scan";
    runtimeInputs = with pkgs; [
      podman
      trivy
      jq
      gawk
      curl
    ];
    text = scriptText;
  };
in
{
  options.custom.services.security.trivy.scanning = with lib; {
    enable = mkEnableOption "Periodic container image scanning on this host";
    serverAddress = mkOption {
      type = types.str;
      default = getHostAddress "vm-monitor";
      description = "Trivy server address.";
    };
    scanners = mkOption {
      type = types.listOf types.str;
      default = [
        "vuln"
        "secret"
      ];
      description = "Trivy scanners to run during each scan.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = lib.mkIf ntfyEnabled {
      ntfy-publisher-environment.file = secretsDir + "/observability/ntfy/trivy-publisher.env.age";
    };

    environment.systemPackages = [ pkgs.trivy ];

    systemd = {
      services.trivy-scan = {
        description = "Trivy container image vulnerability scan";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe scanScript}";
          User = "root";
          LogsDirectory = "trivy";
          CacheDirectory = "trivy";
          EnvironmentFile = lib.optional ntfyEnabled config.age.secrets.ntfy-publisher-environment.path;
        };
      };

      timers.trivy-scan = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = task-schedules.${hostName}.trivy-scan;
          RandomizedDelaySec = 0;
        };
      };
    };
  };
}
