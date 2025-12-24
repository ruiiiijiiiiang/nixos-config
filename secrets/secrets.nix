let
  keys = import ../lib/keys.nix;
in
{
  "cloudflare-token.age" = {
    publicKeys = keys.ssh.pi ++ keys.ssh.vm-network ++ keys.ssh.vm-app;
    armor = true;
  };
  "cloudflare-dns-token.age" = {
    publicKeys = keys.ssh.pi ++ keys.ssh.vm-network ++ keys.ssh.vm-app;
    armor = true;
  };
  "cloudflare-tunnel-token.age" = {
    publicKeys = keys.ssh.vm-app;
    armor = true;
  };
  "dawarich-env.age" = {
    publicKeys = keys.ssh.vm-app;
    armor = true;
  };
  "paperless-env.age" = {
    publicKeys = keys.ssh.vm-app;
    armor = true;
  };
  "vaultwarden-env.age" = {
    publicKeys = keys.ssh.vm-app;
    armor = true;
  };
  "wg-privatekey.age" = {
    publicKeys = keys.ssh.framework;
    armor = true;
  };
  "wg-presharedkey.age" = {
    publicKeys = keys.ssh.framework;
    armor = true;
  };
  "yourls-env.age" = {
    publicKeys = keys.ssh.vm-app;
    armor = true;
  };
}
