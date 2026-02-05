{ inputs, ... }:

{
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
      ];

      substituters = [
        "https://cache.ruijiang.me"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://colmena.cachix.org"
      ];
      trusted-public-keys = [
        "cache.ruijiang.me-1:uSB517/xV6UnlCkzOYvmCSRG0sOqPPAGla5tY4iSQf0="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
      ];

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
}
