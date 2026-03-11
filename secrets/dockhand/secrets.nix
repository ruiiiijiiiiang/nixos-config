let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  "dockhand/agent-crt.age" = {
    publicKeys = ssh.hypervisor ++ ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "dockhand/agent-key.age" = {
    publicKeys = ssh.hypervisor ++ ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
}
