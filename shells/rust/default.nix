{ pkgs, rust-overlay }:
let
  pkgsWithRust = pkgs.extend rust-overlay;
in
with pkgsWithRust;
mkShell {
  buildInputs = [
    (rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
      ];
    })
    clang
    lld
    pkg-config
  ];

  shellHook = ''
    exec fish -l
    echo "  Rust Dev Env Loaded"
  '';
}
