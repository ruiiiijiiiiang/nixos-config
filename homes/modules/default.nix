{ inputs, ... }: {
  imports = [
    inputs.agenix.homeManagerModules.default
    ./core.nix
    ./development.nix
    ./dotfiles.nix
  ];
}
