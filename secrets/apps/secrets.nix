let
  inherit (import ../../lib/keys.nix) ssh;
in
{
  "apps/atuin/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/bytestash/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/dawarich/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/forgejo/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/immich/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/karakeep/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/librechat/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/mealie/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/nextcloud/admin-password.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/nextcloud/onlyoffice-jwt-secret.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/opencloud/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/openwebui/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/ovumcy/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/paperless/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/pocketid/encryption-key.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/pricebuddy/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/reitti/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/searxng/env.age" = {
    publicKeys = ssh.vm-public;
    armor = true;
  };
  "apps/vaultwarden/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
  "apps/yourls/env.age" = {
    publicKeys = ssh.vm-app;
    armor = true;
  };
}
