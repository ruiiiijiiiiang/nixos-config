let
  inherit (import ../../lib/keys.nix) ssh;
  dockhand = import ./dockhand/secrets.nix;
  scanopy = import ./scanopy/secrets.nix;
in
{
  "observability/grafana/secret-key.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "observability/termix/env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "observability/ntfy/server.env.age" = {
    publicKeys = ssh.cloud-observe;
    armor = true;
  };
  "observability/ntfy/gatus-publisher.env.age" = {
    publicKeys = ssh.cloud-observe;
    armor = true;
  };
  "observability/ntfy/trivy-publisher.env.age" = {
    publicKeys = ssh.hypervisor ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor ++ ssh.vm-public;
    armor = true;
  };
  "observability/ntfy/alertmanager-publisher.yml.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
}
// dockhand
// scanopy
