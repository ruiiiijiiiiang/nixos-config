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
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
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
          };
          modules = [ ./hosts/framework ];
        };

        pi = nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs;
            inherit consts;
          };
          modules = [ ./hosts/pi ];
        };

        vm-network = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
          };
          modules = [ ./hosts/vm-network ];
        };

        vm-app = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
          };
          modules = [ ./hosts/vm-app ];
        };

        vm-monitor = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
          };
          modules = [ ./hosts/vm-monitor ];
        };

        vm-security = nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit consts;
          };
          modules = [ ./hosts/vm-security ];
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
          };
        };

        framework = {
          deployment = {
            targetHost = null;
            allowLocalDeployment = true;
            tags = [
              "physical"
              "gui"
            ];
          };
          imports = [ ./hosts/framework ];
        };

        pi = {
          nixpkgs.system = "aarch64-linux";
          deployment = {
            targetHost = addresses.home.hosts.pi;
            tags = [
              "physical"
              "server"
            ];
          };
          imports = [ ./hosts/pi ];
        };

        vm-network = {
          deployment = {
            targetHost = addresses.home.hosts.vm-network;
            tags = [
              "vm"
              "server"
            ];
          };
          imports = [ ./hosts/vm-network ];
        };

        vm-app = {
          deployment = {
            targetHost = addresses.home.hosts.vm-app;
            tags = [
              "vm"
              "server"
            ];
          };
          imports = [ ./hosts/vm-app ];
        };

        vm-monitor = {
          deployment = {
            targetHost = addresses.home.hosts.vm-monitor;
            tags = [
              "vm"
              "server"
            ];
          };
          imports = [ ./hosts/vm-monitor ];
        };

        vm-security = {
          deployment = {
            targetHost = addresses.home.hosts.vm-security;
            tags = [
              "vm"
              "gui"
            ];
          };
          imports = [ ./hosts/vm-security ];
        };
      };

      devShells.${system} = {
        rust = import ./shells/rust { inherit pkgs; };
        devops = import ./shells/devops { inherit pkgs; };
        forensics = import ./shells/forensics { inherit pkgs; };
      };

      homeConfigurations = {
        rui = homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./homes/rui
          ];
        };

        vm-security = homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./homes/vm-security
          ];
        };
      };
    };
}
