{ pkgs }:
with pkgs;
mkShell {
  buildInputs = [
    binaryen
    openssl
    pkg-config
    dioxus-cli
    clang
    lld
    fontconfig
  ];

  OPENSSL_DIR = "${openssl.dev}";
  OPENSSL_LIB_DIR = "${openssl.out}/lib";
  OPENSSL_INCLUDE_DIR = "${openssl.dev}/include";
  LIBCLANG_PATH = "${libclang.lib}/lib";

  shellHook = ''
    exec fish -l
    echo "  Rust Dev Env Loaded"
  '';
}
