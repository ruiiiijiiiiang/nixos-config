{ pkgs }:

pkgs.mkShell {
  name = "forensics-env";

  buildInputs = with pkgs; [
    steghide
    file
    exiftool
    binsider
  ];

  shellHook = ''
    exec fish -l
    echo "🕵️  Forensics Environment Loaded"
  '';
}
