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

  monitoringXml = /* xml */ ''
    <rootcheck>
      <disabled>no</disabled>
      <check_files>yes</check_files>
      <check_trojans>yes</check_trojans>
      <check_dev>yes</check_dev>
      <check_sys>yes</check_sys>
      <check_pids>yes</check_pids>
      <check_ports>yes</check_ports>
      <check_if>yes</check_if>
      <frequency>43200</frequency>
      <rootkit_files>etc/shared/rootkit_files.txt</rootkit_files>
      <rootkit_trojans>etc/shared/rootkit_trojans.txt</rootkit_trojans>
      <skip_nfs>yes</skip_nfs>
      <ignore>/var/lib/containerd</ignore>
      <ignore>/var/lib/docker/overlay2</ignore>
    </rootcheck>

    <wodle name="syscollector">
      <disabled>no</disabled>
      <interval>1h</interval>
      <scan_on_start>yes</scan_on_start>
      <hardware>yes</hardware>
      <network>yes</network>
      <os>yes</os>
      <packages>no</packages>
      <ports all="yes">yes</ports>
      <processes>yes</processes>
      <users>yes</users>
      <groups>yes</groups>
      <services>yes</services>
      <browser_extensions>yes</browser_extensions>
      <synchronization>
        <max_eps>10</max_eps>
      </synchronization>
    </wodle>

    <sca>
      <enabled>yes</enabled>
      <scan_on_start>yes</scan_on_start>
      <interval>12h</interval>
      <skip_nfs>yes</skip_nfs>
    </sca>

    <syscheck>
      <disabled>no</disabled>
      <frequency>43200</frequency>
      <scan_on_start>yes</scan_on_start>
      <ignore>/etc</ignore>
      <ignore>/usr/bin</ignore>
      <ignore type="sregex">.log$|.swp$</ignore>
      <nodiff>/etc/ssl/private.key</nodiff>
      <skip_nfs>yes</skip_nfs>
      <skip_dev>yes</skip_dev>
      <skip_proc>yes</skip_proc>
      <skip_sys>yes</skip_sys>
      <process_priority>10</process_priority>
      <max_eps>50</max_eps>
      <synchronization>
        <enabled>yes</enabled>
        <interval>5m</interval>
        <max_eps>10</max_eps>
      </synchronization>
    </syscheck>

    <localfile>
      <log_format>journald</log_format>
      <location>journald</location>
    </localfile>

    <localfile>
      <log_format>command</log_format>
      <command>df -P /</command>
      <frequency>360</frequency>
    </localfile>

    <localfile>
      <log_format>full_command</log_format>
      <command>netstat -tulpn | sed 's/\([[:alnum:]]\+\)\ \+[[:digit:]]\+\ \+[[:digit:]]\+\ \+\(.*\):\([[:digit:]]*\)\ \+\([0-9\.\:\*]\+\).\+\ \+\([[:digit:]]*\/[[:alnum:]\-]*\).*/\1 \2 == \3 == \4 \5/' | sort -k 4 -g | sed 's/ == \(.*\) ==/:\1/' | sed 1,2d</command>
      <alias>netstat listening ports</alias>
      <frequency>360</frequency>
    </localfile>

    <localfile>
      <log_format>full_command</log_format>
      <command>last -n 20 -f /var/log/wtmp</command>
      <frequency>360</frequency>
    </localfile>

    <active-response>
      <disabled>no</disabled>
      <ca_store>etc/wpk_root.pem</ca_store>
      <ca_verification>yes</ca_verification>
    </active-response>

    <logging>
      <log_format>plain</log_format>
    </logging>
  '';

  nginxXml = /* xml */ ''
    <localfile>
      <log_format>apache</log_format>
      <location>/var/log/nginx/error.log</location>
    </localfile>
    <localfile>
      <log_format>apache</log_format>
      <location>/var/log/nginx/access.log</location>
    </localfile>
  '';

  suricataXml = /* xml */ ''
    <localfile>
      <log_format>json</log_format>
      <location>/var/log/suricata/eve.json</location>
    </localfile>
  '';

  extraConfig = lib.concatStringsSep "\n" [
    monitoringXml
    (lib.optionalString config.custom.services.networking.nginx.enable nginxXml)
    (lib.optionalString config.custom.services.security.suricata.enable suricataXml)
  ];
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
      inherit extraConfig;
    };

    systemd.services.wazuh-agent.path = [
      pkgs.gnused
      pkgs.nettools
      pkgs.util-linux
    ];
  };
}
