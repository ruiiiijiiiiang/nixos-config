let
  inherit (import ../../../lib/keys.nix) ssh;
in
{
  "observability/dockhand/agent-crt.age" = {
    publicKeys =
      ssh.hypervisor ++ ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor ++ ssh.vm-public;
    armor = true;
  };
  "observability/dockhand/agent-key.age" = {
    publicKeys =
      ssh.hypervisor ++ ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor ++ ssh.vm-public;
    armor = true;
  };
}
