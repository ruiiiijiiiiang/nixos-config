{ pkgs }:
with pkgs;
pkgs.mkShell {
  buildInputs = [
    binaryen
    openssl
    pkg-config
    dioxus-cli
  ];

  OPENSSL_DIR = "${openssl.dev}";
  OPENSSL_LIB_DIR = "${openssl.out}/lib";
  OPENSSL_INCLUDE_DIR = "${openssl.dev}/include";

  shellHook = ''
    exec fish -l
    echo "  Rust Dev Env Loaded"
  '';
}
