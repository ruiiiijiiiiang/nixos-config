let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  "personal/copilot/mcp-config.age" = {
    publicKeys = ssh.framework ++ ssh.desktop;
    armor = true;
  };
  "personal/gemini/mcp-config.age" = {
    publicKeys = ssh.framework ++ ssh.desktop;
    armor = true;
  };
  "personal/nix/nix.conf.age" = {
    publicKeys = ssh.framework ++ ssh.desktop;
    armor = true;
  };
  "personal/opencode/config.age" = {
    publicKeys = ssh.framework ++ ssh.desktop;
    armor = true;
  };
  "personal/tryhackme/client.ovpn.age" = {
    publicKeys = ssh.vm-cyber;
    armor = true;
  };
}
