{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  consts = import ../../../lib/consts.nix;
  cfg = config.selfhost.wazuh.agent;
  agentName = config.networking.hostName;
  fileTemplate = import ./ossec.conf.nix;
  fileContent =
    builtins.replaceStrings
      [ "@AGENT_NAME@" "@SERVER_ADDRESS@" ]
      [ agentName consts.addresses.home.hosts.vm-monitor ]
      fileTemplate;
  initialFile = pkgs.writeText "ossec.conf" fileContent;
  targetFile = "/var/wazuh/ossec.conf";
in
with consts;
{
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      wazuh-agent = {
        image = "wazuh/wazuh-agent:4.14.1";
        volumes = [
          "/var/wazuh/ossec.conf:/wazuh-config-mount/etc/ossec.conf"
        ];
        extraOptions = [
          "--network=host"
          "--privileged"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      ports.wazuh.agent.connection
      ports.wazuh.agent.enrollment
    ];

    system.activationScripts.wazuh-agent-init = ''
      mkdir -p $(dirname ${targetFile})
      if [ ! -f ${targetFile} ]; then
        echo "Initializing ${targetFile} ..."
        cat ${initialFile} > ${targetFile}
        chmod 640 ${targetFile}
      else
        echo "${targetFile} already exists. Skipping initialization."
      fi
    '';
  };
}
