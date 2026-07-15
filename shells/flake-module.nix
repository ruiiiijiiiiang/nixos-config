{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    devShells = {
      nix = import ../shells/nix { inherit pkgs; };
      node = import ../shells/node { inherit pkgs; };
      python = import ../shells/python { inherit pkgs; };
      rust = import ../shells/rust {
        inherit pkgs;
        rust-overlay = inputs.rust-overlay.overlays.default;
      };
    };
  };
}
