let
  keys = import ../lib/keys.nix;
in
{
  "beszel-key.age".publicKeys = keys.ssh.rui-nixos-pi;
  "cloudflare-token.age".publicKeys = keys.ssh.rui-nixos-pi;
  "cloudflare-dns-token.age".publicKeys = keys.ssh.rui-nixos-pi;
  "cloudflare-tunnel-token.age".publicKeys = keys.ssh.rui-nixos-pi;
  "vaultwarden-env.age".publicKeys = keys.ssh.rui-nixos-pi;
  "wg-privatekey.age".publicKeys = keys.ssh.rui-nixos;
  "wg-presharedkey.age".publicKeys = keys.ssh.rui-nixos;
}
