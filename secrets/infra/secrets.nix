let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  "infra/harmonia/signing-key.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "infra/restic/password.age" = {
    publicKeys = ssh.hypervisor ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "infra/restic/rclone.conf.age" = {
    publicKeys = ssh.hypervisor ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
}
