let
  inherit (import ../../lib/keys.nix) ssh;
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
  "security/wazuh/env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
}
