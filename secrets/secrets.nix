let
  inherit (import ../lib/keys.nix) ssh;
in
{
  "bytestash-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
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
  "forgejo-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "geoip-key.age" = {
    publicKeys = ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
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
  "pocketid-encryption-key.age" = {
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
  "scanopy/daemon-pi-env.age" = {
    publicKeys = ssh.pi;
    armor = true;
  };
  "scanopy/daemon-vm-app-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "scanopy/daemon-vm-monitor-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "scanopy/daemon-vm-network-env.age" = {
    publicKeys = ssh.vm-network;
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
  "wireguard/framework-preshared-key.age" = {
    publicKeys = ssh.vm-network ++ ssh.framework;
    armor = true;
  };
  "wireguard/framework-private-key.age" = {
    publicKeys = ssh.framework;
    armor = true;
  };
  "wireguard/iphone-16-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/iphone-17-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/github-action-preshared-key.age" = {
    publicKeys = ssh.vm-network;
    armor = true;
  };
  "wireguard/proton-private-key.age" = {
    publicKeys = ssh.vm-app;
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
