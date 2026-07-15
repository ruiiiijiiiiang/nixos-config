{ pkgs }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    nil
    nixfmt
    statix
  ];

  shellHook = ''
    echo "❄️ NixOS Config Dev Env Loaded"
  '';
}
