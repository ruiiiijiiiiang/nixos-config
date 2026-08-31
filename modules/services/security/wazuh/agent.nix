{
  config,
  consts,
  helpers,
  lib,
  pkgs,
  ...
}:
let
  inherit (consts) ports;
  inherit (helpers) getHostAddress;
  cfg = config.custom.services.security.wazuh.agent;

  nginxXml = ''
    <localfile>
      <log_format>apache</log_format>
      <location>/var/log/nginx/error.log</location>
    </localfile>
    <localfile>
      <log_format>apache</log_format>
      <location>/var/log/nginx/access.log</location>
    </localfile>
  '';

  suricataXml = ''
    <localfile>
      <log_format>json</log_format>
      <location>/var/log/suricata/eve.json</location>
    </localfile>
  '';

  extraLocalfiles = lib.concatStringsSep "\n" [
    (lib.optionalString config.custom.services.networking.nginx.enable nginxXml)
    (lib.optionalString config.custom.services.security.suricata.enable suricataXml)
  ];

  ossecConfig =
    lib.replaceStrings
      [ "@AGENT_NAME@" "@SERVER_ADDRESS@" "@EXTRA_LOCALFILES@" ]
      [ config.networking.hostName cfg.serverAddress extraLocalfiles ]
      (lib.readFile ./ossec.conf);
in
{
  options.custom.services.security.wazuh.agent = {
    enable = lib.mkEnableOption "Wazuh agent";
    serverAddress = lib.mkOption {
      type = lib.types.str;
      default = getHostAddress "vm-monitor";
      description = "Wazuh manager address.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.wazuh.agent = {
      enable = true;
      managerAddress = cfg.serverAddress;
      managerPort = ports.wazuh.agent.connection;
      enrollmentPort = ports.wazuh.agent.enrollment;
      config = ossecConfig;
    };

    systemd.services.wazuh-agent.path = [
      pkgs.gnused
      pkgs.nettools
      pkgs.util-linux
    ];
  };
}
