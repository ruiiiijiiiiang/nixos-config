let
  apps = import ./apps/secrets.nix;
  infra = import ./infra/secrets.nix;
  networking = import ./networking/secrets.nix;
  observability = import ./observability/secrets.nix;
  personal = import ./personal/secrets.nix;
  security = import ./security/secrets.nix;
in
apps // infra // networking // observability // personal // security
