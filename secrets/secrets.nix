let
  keys = import ../lib/keys.nix;
in
with keys;
{
  "cloudflare-token.age" = {
    publicKeys = ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "cloudflare-dns-token.age" = {
    publicKeys = ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "cloudflare-tunnel-token.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "dawarich-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "paperless-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "vaultwarden-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "wg-privatekey.age" = {
    publicKeys = ssh.framework;
    armor = true;
  };
  "wg-presharedkey.age" = {
    publicKeys = ssh.framework;
    armor = true;
  };
  "wazuh-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "yourls-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
}
