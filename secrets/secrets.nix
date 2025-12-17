let
  keys = import ../lib/keys.nix;
in
{
  "beszel-key.age".publicKeys = keys.ssh.pi ++ keys.ssh.vm-app;
  "cloudflare-token.age".publicKeys = keys.ssh.pi ++ keys.ssh.vm-network ++ keys.ssh.vm-app;
  "cloudflare-dns-token.age".publicKeys = keys.ssh.pi ++ keys.ssh.vm-network ++ keys.ssh.vm-app;
  "cloudflare-tunnel-token.age".publicKeys = keys.ssh.vm-app;
  "vaultwarden-env.age".publicKeys = keys.ssh.vm-app;
  "wg-privatekey.age".publicKeys = keys.ssh.framework;
  "wg-presharedkey.age".publicKeys = keys.ssh.framework;
}
