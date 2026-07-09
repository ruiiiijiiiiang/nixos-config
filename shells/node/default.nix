{ pkgs }:
with pkgs;
mkShell {
  buildInputs = [
    pnpm
    svelte-language-server
    tailwindcss-language-server
    typescript-language-server
    vscode-js-debug
    vscode-langservers-extracted
    vtsls
  ];

  shellHook = ''
    exec fish -l
    echo "  Node.js / pnpm Dev Env Loaded"
  '';
}
