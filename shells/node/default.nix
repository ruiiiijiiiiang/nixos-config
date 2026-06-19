{ pkgs }:
with pkgs;
mkShell {
  buildInputs = [
    nodejs_24
    pnpm
  ];

  shellHook = ''
    exec fish -l
    echo "  Node.js / pnpm Dev Env Loaded"
  '';
}
