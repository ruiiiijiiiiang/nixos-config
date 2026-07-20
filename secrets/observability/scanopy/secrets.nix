let
  inherit (import ../../../lib/keys.nix) ssh;
in
{
  "observability/scanopy/server-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "observability/scanopy/daemon-pi-env.age" = {
    publicKeys = ssh.pi;
    armor = true;
  };
  "observability/scanopy/daemon-vm-app-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "observability/scanopy/daemon-vm-monitor-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "observability/scanopy/daemon-vm-network-env.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
}
