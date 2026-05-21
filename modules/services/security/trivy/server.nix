{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) ports;
  cfg = config.custom.services.security.trivy.server;
in
{
  options.custom.services.security.trivy.server = with lib; {
    enable = mkEnableOption "Trivy vulnerability scanner server (centralized DB)";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.trivy-server = {
      description = "Trivy Vulnerability Scanner Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.trivy}/bin/trivy server --listen 0.0.0.0:${toString ports.trivy}";
        DynamicUser = true;
        StateDirectory = "trivy";
        Restart = "always";
        RestartSec = 5;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ ports.trivy ];
  };
}
