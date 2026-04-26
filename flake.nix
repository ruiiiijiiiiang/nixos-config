{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles.url = "github:ruiiiijiiiiang/dotfiles";
    file_clipper.url = "github:ruiiiijiiiiang/file_clipper";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazynmap.url = "github:ruiiiijiiiiang/lazynmap";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    niri.url = "github:sodiboo/niri-flake";
    NixVirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rs-top.url = "github:ruiiiijiiiiang/rs-top";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    website.url = "github:ruiiiijiiiiang/website";
    wezterm = {
      url = "github:wezterm/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    witr.url = "github:pranshuparmar/witr";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.rust-overlay.overlays.default ];
            config.allowUnfree = true;
          };
        };

      imports = [
        ./hosts/flake-module.nix
        ./homes/flake-module.nix
        ./shells/flake-module.nix
      ];
    };
}
