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
      inputs.dgop.follows = "dgop";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    file_clipper.url = "github:ruiiiijiiiiang/file_clipper";
    lazynmap.url = "github:ruiiiijiiiiang/lazynmap";
    noxdir.url = "github:crumbyte/noxdir";
    doxx.url = "github:bgreenwell/doxx";
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
      inherit (nixpkgs.lib) nixosSystem;
      inherit (home-manager.lib) homeManagerConfiguration;
    in
    {
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
            ./systems/pi
          ];
        };

        rui-nixos-vm-network = nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./systems/vm-network
          ];
        };
      };

      devShells.${system} = {
        rust = import ./shells/rust { inherit pkgs; };
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
