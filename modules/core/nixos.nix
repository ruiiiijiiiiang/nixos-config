{ inputs, pkgs, ... }:

{
  imports = [ inputs.nixos-cis-validator.nixosModules.default ];

  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    registry.nixpkgs.flake = inputs.nixpkgs;

    settings = {
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
      dates = [ "weekly" ];
    };

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  security.cisValidator = {
    enable = pkgs.stdenv.hostPlatform.isx86_64;
    profile = "ubuntu-24.04-l1-server";
    failureMode = "warn";
  };
}
