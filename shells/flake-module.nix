{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.rust = import ../shells/rust {
      inherit pkgs;
      rust-overlay = inputs.rust-overlay.overlays.default;
    };
    devShells.node = import ../shells/node { inherit pkgs; };
    devShells.python = import ../shells/python { inherit pkgs; };
  };
}
