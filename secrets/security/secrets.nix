let
  inherit (import ../../lib/keys.nix) ssh;
  wazuhSecret = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
in
{
  "security/krawl/env.age" = {
    publicKeys = ssh.vm-public;
    armor = true;
  };
  "security/maxmind/license-key.age" = {
    publicKeys = ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor ++ ssh.vm-public;
    armor = true;
  };
  "security/wazuh/env.age" = wazuhSecret;
  "security/wazuh/root-ca.age" = wazuhSecret;
  "security/wazuh/indexer-cert.age" = wazuhSecret;
  "security/wazuh/indexer-key.age" = wazuhSecret;
  "security/wazuh/admin-cert.age" = wazuhSecret;
  "security/wazuh/admin-key.age" = wazuhSecret;
  "security/wazuh/filebeat-cert.age" = wazuhSecret;
  "security/wazuh/filebeat-key.age" = wazuhSecret;
}
