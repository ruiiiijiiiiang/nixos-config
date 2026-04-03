let
  inherit (import ../lib/keys.nix) ssh;
  dockhand = import ./dockhand/secrets.nix;
  scanopy = import ./scanopy/secrets.nix;
  wireguard = import ./wireguard/secrets.nix;
in
{
  "atuin-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "bytestash-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "cloudflare-token.age" = {
    publicKeys = ssh.hypervisor ++ ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "cloudflare-dns-token.age" = {
    publicKeys = ssh.hypervisor ++ ssh.pi ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
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
  "forgejo-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "maxmind-license-key.age" = {
    publicKeys = ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "grafana-secret-key.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "harmonia-sign-key.age" = {
    publicKeys = ssh.vm-app;
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
  "openwebui-env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "ovumcy-env.age" = {
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
  "restic-password.age" = {
    publicKeys = ssh.hypervisor ++ ssh.vm-network ++ ssh.vm-app ++ ssh.vm-monitor;
    armor = true;
  };
  "termix-env.age" = {
    publicKeys = ssh.vm-monitor;
    armor = true;
  };
  "tryhackme-ovpn.age" = {
    publicKeys = ssh.vm-cyber;
    armor = true;
  };
  "vaultwarden-env.age" = {
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
// dockhand
// scanopy
// wireguard
