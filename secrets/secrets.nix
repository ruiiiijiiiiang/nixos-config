let
  keys = import ../lib/keys.nix;
in
{
  "beszel-key.age".publicKeys = keys.ssh.rui-nixos-pi;
  "cloudflare-token.age".publicKeys =
    keys.ssh.rui-nixos-pi ++ keys.ssh.rui-nixos-vm-network ++ keys.ssh.rui-nixos-vm-app;
  "cloudflare-dns-token.age".publicKeys =
    keys.ssh.rui-nixos-pi ++ keys.ssh.rui-nixos-vm-network ++ keys.ssh.rui-nixos-vm-app;
  "cloudflare-tunnel-token.age".publicKeys = keys.ssh.rui-nixos-pi ++ keys.ssh.rui-nixos-vm-app;
  "vaultwarden-env.age".publicKeys = keys.ssh.rui-nixos-pi ++ keys.ssh.rui-nixos-vm-app;
  "wg-privatekey.age".publicKeys = keys.ssh.rui-nixos;
  "wg-presharedkey.age".publicKeys = keys.ssh.rui-nixos;
}
