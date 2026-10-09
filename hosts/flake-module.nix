{
  inputs,
  lib,
  self,
  ...
}:
let
  consts = import ../lib/consts.nix;
  keys = import ../lib/keys.nix;
  secrets = import ../secrets/secrets.nix;
  secretsDir = ../secrets;

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
            keys
            dotfilesRoot
            secretsDir
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
      platformModules ? [ ],
      homeConfig ? null,
      dotfilesSource ? "flake",
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          consts
          inputs
          helpers
          keys
          secrets
          secretsDir
          ;
      };
      modules = [
        ../modules
        ../hosts/${hostname}.nix
      ]
      ++ platformModules
      ++ hardware
      ++ lib.optionals (homeConfig != null) [
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule { inherit homeConfig dotfilesSource; })
      ];
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      apps.rekey-secrets = inputs.agenix-rekey-helper.lib.mkRekeyApp {
        inherit pkgs;
        rules = "secrets/secrets.nix";
        sources = [
          "secrets"
          "lib/keys.nix"
        ];
        hosts =
          lib.mapAttrs
            (hostname: _: {
              target = "root@${hostname}";
              identity = "/etc/ssh/ssh_host_ed25519_key";
            })
            (
              lib.filterAttrs (
                _: host: host.config.custom.roles.headless.services.enable
              ) self.nixosConfigurations
            );
      };
    };

  flake.nixosConfigurations = {
    framework = mkHost "framework" {
      hardware = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];
      dotfilesSource = "local";
      homeConfig = ../homes/configs/framework.nix;
    };

    desktop = mkHost "desktop" {
      dotfilesSource = "local";
      homeConfig = ../homes/configs/desktop.nix;
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

    cloud-observe = mkHost "cloud-observe" {
      platformModules = [ ../modules/platforms/cloud/aws/image.nix ];
      homeConfig = ../homes/configs/headless.nix;
    };
  };
}
