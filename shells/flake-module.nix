{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.rust = import ../shells/rust { inherit pkgs; };
  };
}
