{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.rust = import ../shells/rust { inherit pkgs; };
    devShells.node = import ../shells/node { inherit pkgs; };
  };
}
