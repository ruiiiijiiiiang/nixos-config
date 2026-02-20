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
    agenix.url = "github:ryantm/agenix";
    colmena.url = "github:zhaofengli/colmena";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    file_clipper.url = "github:ruiiiijiiiiang/file_clipper";
    lazynmap.url = "github:ruiiiijiiiiang/lazynmap";
    noxdir.url = "github:crumbyte/noxdir";
    witr.url = "github:pranshuparmar/witr";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      consts = import ./lib/consts.nix;
      helpers = import ./lib/helpers.nix {
        inherit (nixpkgs) lib;
        inherit consts;
        inherit pkgs;
      };
      inherit (nixpkgs.lib) nixosSystem;
      inherit (home-manager.lib) homeManagerConfiguration;
    in
    {
      nixosConfigurations = {
        framework = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./modules
            ./hosts/framework
          ];
        };

        pi = nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./modules
            ./hosts/pi
          ];
        };

        vm-network = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-network
          ];
        };

        vm-app = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-app
          ];
        };

        vm-monitor = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-monitor
          ];
        };

        vm-cyber = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./modules
            ./hosts/vm-cyber
          ];
        };
      };

      colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
      colmena = with consts; {
        meta = {
          nixpkgs = import nixpkgs {
            inherit system;
          };
          specialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
        };

        framework = {
          deployment = {
            targetHost = null;
            allowLocalDeployment = true;
            tags = [
              "physical"
              "workstation"
            ];
          };
          imports = [
            ./modules
            ./hosts/framework
          ];
        };

        pi = {
          nixpkgs.system = "aarch64-linux";
          deployment = {
            targetHost = addresses.infra.hosts.pi;
            tags = [
              "physical"
              "server"
            ];
          };
          imports = [
            ./modules
            ./hosts/pi
          ];
        };

        vm-network = {
          deployment = {
            targetHost = addresses.infra.hosts.vm-network;
            tags = [
              "vm"
              "server"
            ];
          };
          imports = [
            ./modules
            ./hosts/vm-network
          ];
        };

        vm-app = {
          deployment = {
            targetHost = addresses.infra.hosts.vm-app;
            tags = [
              "vm"
              "server"
            ];
          };
          imports = [
            ./modules
            ./hosts/vm-app
          ];
        };

        vm-monitor = {
          deployment = {
            targetHost = addresses.infra.hosts.vm-monitor;
            tags = [
              "vm"
              "server"
            ];
          };
          imports = [
            ./modules
            ./hosts/vm-monitor
          ];
        };

        vm-cyber = {
          deployment = {
            targetHost = addresses.dmz.hosts.vm-cyber;
            tags = [
              "vm"
              "workstation"
            ];
          };
          imports = [
            ./modules
            ./hosts/vm-cyber
          ];
        };
      };

      devShells.${system} = {
        rust = import ./shells/rust { inherit pkgs; };
        devops = import ./shells/devops { inherit pkgs; };
        forensics = import ./shells/forensics { inherit pkgs; };
      };

      homeConfigurations = {
        framework = homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./homes/framework
          ];
        };

        arch = homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./homes/arch
          ];
        };

        vm-cyber = homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            inherit consts;
            inherit helpers;
          };
          modules = [
            ./homes/vm-cyber
          ];
        };
      };
    };
}
