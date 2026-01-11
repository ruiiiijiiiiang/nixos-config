let
  inherit (import ../lib/keys.nix) ssh;
in
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
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "dawarich-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "dockhand/agent-crt.age" = {
    publicKeys = ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "dockhand/agent-key.age" = {
    publicKeys = ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "immich-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "karakeep-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "memos-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "nextcloud-pass.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "oauth2-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "onlyoffice-secret.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "opencloud-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "paperless-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "reitti-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "scanopy/server-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "scanopy/daemon-env.age" = {
    publicKeys = ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "vaultwarden-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "wireguard/server-private-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/iphone-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/framework-preshared-key.age" = {
    publicKeys = ssh.vm-network ++ ssh.framework;
    armor = true;
  };
  "wireguard/framework-private-key.age" = {
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
