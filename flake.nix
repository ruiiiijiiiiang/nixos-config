{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    file_clipper.url = "github:ruiiiijiiiiang/file_clipper";
    lazynmap.url = "github:ruiiiijiiiiang/lazynmap";
    noxdir.url = "github:crumbyte/noxdir";
    doxx.url = "github:bgreenwell/doxx";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    ...
  }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    inherit (nixpkgs.lib) nixosSystem;
    inherit (home-manager.lib) homeManagerConfiguration;
  in {
    nixosConfigurations = {
      rui-nixos = nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./systems/framework
        ];
      };

      rui-nixos-vm = nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./systems/vm
        ];
      };

      rui-nixos-pi = nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ({ modulesPath, ...}: {
            imports = [
              "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
            ];
            sdImage.compressImage = false;
          })
          nixos-hardware.nixosModules.raspberry-pi-4
          ./systems/pi
        ];
      };
    };

    devShells.${system} = {
      devops = import ./shells/devops { inherit pkgs; };
      forensics = import ./shells/forensics { inherit pkgs; };
      default = self.devShells.${system}.devops;
    };

    homeConfigurations = {
      rui = homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./homes/rui
        ];
      };

      rui-vm = homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./homes/vm
        ];
      };
    };
  };
}
