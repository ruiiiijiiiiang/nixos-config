{
  config,
  consts,
  helpers,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) daily-tasks ports endpoints;
  inherit (helpers) dailyTaskToSystemd getHostAddress;
  cfg = config.custom.services.security.trivy.scanning;
  hostName = config.networking.hostName;
  ntfyEnabled =
    inputs.self.nixosConfigurations.vm-monitor.config.custom.services.observability.ntfy.enable;

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
        (lib.escapeShellArg endpoints.ntfy-topics.trivy)
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
        };
      };

      timers.trivy-scan = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = dailyTaskToSystemd daily-tasks.${hostName}.trivy-scan;
          RandomizedDelaySec = 0;
        };
      };
    };
  };
}
