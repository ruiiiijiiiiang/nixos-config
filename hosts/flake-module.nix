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
      dotfilesRoot,
      dotfilesOutOfStore,
      homeConfig,
    }:
    lib.recursiveUpdate
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
              dotfilesOutOfStore
              ;
          };
        };
      }
      {
        home-manager.users.${username}.imports = [
          ../homes/modules
          homeConfig
        ];
      };
in
{
  flake.nixosConfigurations = {
    framework = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/framework.nix
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule {
          dotfilesRoot = "${home}/dotfiles";
          dotfilesOutOfStore = true;
          homeConfig = ../homes/configs/framework.nix;
        })
      ];
    };

    pi = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/pi.nix
      ];
    };

    hypervisor = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/hypervisor.nix
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule {
          dotfilesRoot = inputs.dotfiles.lib.source;
          dotfilesOutOfStore = false;
          homeConfig = ../homes/configs/headless.nix;
        })
      ];
    };

    vm-network = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/vm-network.nix
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule {
          dotfilesRoot = inputs.dotfiles.lib.source;
          dotfilesOutOfStore = false;
          homeConfig = ../homes/configs/headless.nix;
        })
      ];
    };

    vm-app = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/vm-app.nix
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule {
          dotfilesRoot = inputs.dotfiles.lib.source;
          dotfilesOutOfStore = false;
          homeConfig = ../homes/configs/headless.nix;
        })
      ];
    };

    vm-monitor = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/vm-monitor.nix
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule {
          dotfilesRoot = inputs.dotfiles.lib.source;
          dotfilesOutOfStore = false;
          homeConfig = ../homes/configs/headless.nix;
        })
      ];
    };

    vm-public = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/vm-public.nix
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule {
          dotfilesRoot = inputs.dotfiles.lib.source;
          dotfilesOutOfStore = false;
          homeConfig = ../homes/configs/headless.nix;
        })
      ];
    };

    vm-cyber = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit consts inputs helpers;
      };
      modules = [
        ../modules
        ../hosts/vm-cyber.nix
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManagerModule {
          dotfilesRoot = inputs.dotfiles.lib.source;
          dotfilesOutOfStore = false;
          homeConfig = ../homes/configs/vm-cyber.nix;
        })
      ];
    };
  };
}
