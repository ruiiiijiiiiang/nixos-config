{ inputs, lib, ... }:
let
  consts = import ../lib/consts.nix;

  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  helpers = import ../lib/helpers.nix {
    inherit consts lib pkgs;
  };

  inherit (consts) username home;

  mkHomeManagerModule =
    {
      homeConfig,
      dotfilesSource,
    }:
    let
      dotfilesRoot =
        {
          flake = inputs.dotfiles.lib.source;
          local = "${home}/dotfiles";
        }
        .${dotfilesSource};
    in
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit
            consts
            inputs
            helpers
            dotfilesRoot
            ;
        };
        users.${username}.imports = [
          ../homes/modules
          homeConfig
        ];
      };
    };

  mkHost =
    hostname:
    {
      system ? "x86_64-linux",
      hardware ? [ ],
      homeConfig ? null,
      dotfilesSource ? "flake",
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/${hostname}.nix
      ]
      ++ hardware
      ++ lib.optionals (homeConfig != null) [
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule { inherit homeConfig dotfilesSource; })
      ];
    };
in
{
  flake.nixosConfigurations = {
    framework = mkHost "framework" {
      hardware = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];
      dotfilesSource = "local";
      homeConfig = ../homes/configs/framework.nix;
    };

    pi = mkHost "pi" {
      system = "aarch64-linux";
      hardware = [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];
    };

    hypervisor = mkHost "hypervisor" {
      hardware = [ inputs.nixos-hardware.nixosModules.minisforum-um690 ];
      homeConfig = ../homes/configs/headless.nix;
    };

    vm-network = mkHost "vm-network" {
      homeConfig = ../homes/configs/headless.nix;
    };

    vm-app = mkHost "vm-app" {
      homeConfig = ../homes/configs/headless.nix;
    };

    vm-monitor = mkHost "vm-monitor" {
      homeConfig = ../homes/configs/headless.nix;
    };

    vm-public = mkHost "vm-public" {
      homeConfig = ../homes/configs/headless.nix;
    };

    vm-cyber = mkHost "vm-cyber" {
      homeConfig = ../homes/configs/vm-cyber.nix;
    };
  };
}
