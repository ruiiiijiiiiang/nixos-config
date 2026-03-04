let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  "scanopy/server-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "scanopy/daemon-pi-env.age" = {
    publicKeys = ssh.pi;
    armor = true;
  };
  "scanopy/daemon-vm-app-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "scanopy/daemon-vm-monitor-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "scanopy/daemon-vm-network-env.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
}
