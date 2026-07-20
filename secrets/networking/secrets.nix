let
  inherit (import ../../lib/keys.nix) ssh;
  wireguard = import ./wireguard/secrets.nix;
in
{
  "networking/cloudflare/nginx-token.age" = {
    publicKeys =
      ssh.hypervisor ++ ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor ++ ssh.vm-public;
    armor = true;
  };
  "networking/cloudflare/dns-token.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "networking/cloudflare/tunnel-token.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
}
// wireguard
