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
}
// dockhand
// scanopy
