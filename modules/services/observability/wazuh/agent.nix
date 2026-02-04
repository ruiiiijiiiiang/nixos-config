{
  config,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  inherit (import ../../../../lib/consts.nix) addresses ports;
  inherit (helpers) ensureFile;
  cfg = config.custom.services.observability.wazuh.agent;

  nginxXml = ''
    <localfile>
      <log_format>apache</log_format>
      <location>/var/log/nginx/error.log</location>
    </localfile>
  '';

  suricataXml = ''
    <localfile>
      <log_format>json</log_format>
      <location>/var/log/suricata/eve.json</location>
    </localfile>
  '';

  extraLocalfiles = lib.concatStringsSep "\n" [
    (if config.custom.services.networking.suricata.enable
    then suricataXml
    else "")
    (if config.custom.services.networking.nginx.enable
    then nginxXml
    else "")
  ];

  ossecTemplate = import ./ossec.conf.nix;
  ossecContent =
    builtins.replaceStrings
      [ "@AGENT_NAME@" "@SERVER_ADDRESS@" "@EXTRA_LOCALFILES@" ]
      [ config.networking.hostName addresses.infra.hosts.vm-monitor extraLocalfiles ]
      ossecTemplate;
  initialFile = pkgs.writeText "ossec.conf" ossecContent;

  ossecFile = "/var/wazuh/ossec.conf";
  keysFile = "/var/wazuh/client.keys";
in
{
  options.custom.services.observability.wazuh.agent = with lib; {
    enable = mkEnableOption "Wazuh security monitoring agent";
    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Interface to open ports";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      wazuh-agent = {
        image = "wazuh/wazuh-agent:${config.custom.services.observability.wazuh.version}";
        volumes = [
          "/var/wazuh/ossec.conf:/wazuh-config-mount/etc/ossec.conf"
          "/var/wazuh/client.keys:/var/ossec/etc/client.keys"
          "/:/host:ro"
          "/sys:/host/sys:ro"
          "/proc:/host/proc:ro"
          "/var/log:/var/log:ro"
          "/etc/machine-id:/etc/machine-id:ro"
          "/etc/os-release:/etc/os-release:ro"
        ];
        networks = [ "host" ];
        privileged = true;
        extraOptions = [ "--pid=host" ];
      };
    };

    networking.firewall =
      if cfg.interface != null then
        {
          interfaces."${cfg.interface}".allowedTCPPorts = [
            ports.wazuh.agent.connection
            ports.wazuh.agent.enrollment
          ];
        }
      else
        {
          allowedTCPPorts = [
            ports.wazuh.agent.connection
            ports.wazuh.agent.enrollment
          ];
        };

    system.activationScripts.wazuh-agent-init = ''
      ${ensureFile {
        source = initialFile;
        destination = ossecFile;
      }}
      if [ ! -f ${keysFile} ]; then
        echo "Initializing empty ${keysFile} ..."
        touch ${keysFile}
        chmod 666 ${keysFile}
      else
        echo "${keysFile} already exists. Preserving identity."
      fi
    '';
  };
}
