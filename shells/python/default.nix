{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    python314
    python314Packages.debugpy
    pyright
    ruff
  ];

  shellHook = ''
    exec fish -l
    echo "🐍  Python Dev Env Loaded"
  '';
}
