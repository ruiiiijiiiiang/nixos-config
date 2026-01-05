{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ../../../lib/consts.nix) addresses ports;
  cfg = config.selfhost.wazuh.agent;
  agentName = config.networking.hostName;
  ossecTemplate = import ./ossec.conf.nix;
  ossecContent =
    builtins.replaceStrings
      [ "@AGENT_NAME@" "@SERVER_ADDRESS@" ]
      [ agentName addresses.home.hosts.vm-monitor ]
      ossecTemplate;
  initialFile = pkgs.writeText "ossec.conf" ossecContent;
  ossecFile = "/var/wazuh/ossec.conf";
  keysFile = "/var/wazuh/client.keys";
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      wazuh-agent = {
        image = "wazuh/wazuh-agent:4.14.1";
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
        extraOptions = [
          "--privileged"
          "--pid=host"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      ports.wazuh.agent.connection
      ports.wazuh.agent.enrollment
    ];

    system.activationScripts.wazuh-agent-init = ''
      mkdir -p $(dirname ${ossecFile})
      if [ ! -f ${ossecFile} ]; then
        echo "Initializing ${ossecFile} ..."
        cat ${initialFile} > ${ossecFile}
        chmod 640 ${ossecFile}
      else
        echo "${ossecFile} already exists. Skipping initialization."
      fi
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
