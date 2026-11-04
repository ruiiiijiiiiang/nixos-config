{
  consts,
  inputs,
  lib,
  ...
}:

let
  inherit (consts) task-schedules;
  inherit (lib) mkDefault;
in
{
  imports = [ inputs.nixos-cis-validator.nixosModules.default ];

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;

    daemonCPUSchedPolicy = mkDefault "batch";
    daemonIOSchedClass = mkDefault "best-effort";
    daemonIOSchedPriority = mkDefault 7;

    settings = {
      nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];

      builders-use-substitutes = mkDefault true;

      min-free = mkDefault (1024 * 1024 * 1024);
      max-free = mkDefault (3 * 1024 * 1024 * 1024);

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      sandbox = true;
      trusted-users = [
        "root"
        "@wheel"
        "forgejo"
      ];

      substituters = [
        "https://cache.ruijiang.me"
        "https://nix-community.cachix.org"
        "https://wezterm.cachix.org"
        "https://noctalia.cachix.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "cache.ruijiang.me-1:uSB517/xV6UnlCkzOYvmCSRG0sOqPPAGla5tY4iSQf0="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
      http2 = false;
      connect-timeout = 10;
      download-attempts = 10;
      stalled-download-timeout = 10;
      fallback = true;

      auto-optimise-store = true;
    };

    optimise = {
      automatic = true;
      dates = [ task-schedules.common.nix-optimise ];
    };

    gc = {
      automatic = true;
      dates = task-schedules.common.nix-gc;
      options = "--delete-older-than 7d";
    };
  };

  systemd.services = {
    nix-daemon.serviceConfig = {
      OOMScoreAdjust = mkDefault 250;
    };

    nix-gc.serviceConfig = {
      CPUSchedulingPolicy = mkDefault "batch";
      IOSchedulingClass = mkDefault "best-effort";
      IOSchedulingPriority = mkDefault 7;
    };
  };
}
