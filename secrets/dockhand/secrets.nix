let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  # TODO: regen
  "dockhand/agent-crt.age" = {
    publicKeys = ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  # TODO: regen
  "dockhand/agent-key.age" = {
    publicKeys = ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
}
