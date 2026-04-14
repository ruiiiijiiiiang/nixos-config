{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixVirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wezterm = {
      url = "github:wezterm/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    file_clipper.url = "github:ruiiiijiiiiang/file_clipper";
    lazynmap.url = "github:ruiiiijiiiiang/lazynmap";
    witr.url = "github:pranshuparmar/witr";
    dotfiles.url = "github:ruiiiijiiiiang/dotfiles";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      dotfiles,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      inherit (nixpkgs) lib;

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      consts = import ./lib/consts.nix;
      helpers = import ./lib/helpers.nix {
        inherit consts lib pkgs;
      };
      inherit (consts) username home;

      mkHomeManagerModule =
        {
          dotfilesRoot,
          dotfilesOutOfStore,
          homeModules,
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
              homeModules
              homeConfig
            ];
          };
    in
    {
      nixosConfigurations = {
        framework = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/framework.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule {
              dotfilesRoot = "${home}/dotfiles";
              dotfilesOutOfStore = true;
              homeModules = ./homes/modules;
              homeConfig = ./homes/configs/framework.nix;
            })
          ];
        };

        pi = lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/pi.nix
          ];
        };

        hypervisor = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/hypervisor.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule {
              dotfilesRoot = dotfiles.lib.source;
              dotfilesOutOfStore = false;
              homeModules = ./homes/modules;
              homeConfig = ./homes/configs/headless.nix;
            })
          ];
        };

        vm-network = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-network.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule {
              dotfilesRoot = dotfiles.lib.source;
              dotfilesOutOfStore = false;
              homeModules = ./homes/modules;
              homeConfig = ./homes/configs/headless.nix;
            })
          ];
        };

        vm-app = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-app.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule {
              dotfilesRoot = dotfiles.lib.source;
              dotfilesOutOfStore = false;
              homeModules = ./homes/modules;
              homeConfig = ./homes/configs/headless.nix;
            })
          ];
        };

        vm-monitor = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-monitor.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule {
              dotfilesRoot = dotfiles.lib.source;
              dotfilesOutOfStore = false;
              homeModules = ./homes/modules;
              homeConfig = ./homes/configs/headless.nix;
            })
          ];
        };

        vm-public = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-public.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule {
              dotfilesRoot = dotfiles.lib.source;
              dotfilesOutOfStore = false;
              homeModules = ./homes/modules;
              homeConfig = ./homes/configs/headless.nix;
            })
          ];
        };

        vm-cyber = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit consts inputs helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-cyber.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule {
              dotfilesRoot = dotfiles.lib.source;
              dotfilesOutOfStore = false;
              homeModules = ./homes/modules;
              homeConfig = ./homes/configs/vm-cyber.nix;
            })
          ];
        };
      };

      devShells.${system} = {
        rust = import ./shells/rust { inherit pkgs; };
        devops = import ./shells/devops { inherit pkgs; };
        forensics = import ./shells/forensics { inherit pkgs; };
      };

      homeConfigurations = {
        arch = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit consts inputs helpers;
            dotfilesRoot = "${home}/dotfiles";
            dotfilesOutOfStore = true;
          };
          modules = [
            ./homes/modules
            ./homes/configs/arch.nix
          ];
        };
      };
    };
}
