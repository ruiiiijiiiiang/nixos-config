{ pkgs }:

pkgs.mkShell {
  name = "forensics-env";

  buildInputs = with pkgs; [
    binwalk
    steghide
    file
    exiftool
    binsider
    zsteg
  ];

  shellHook = ''
    exec fish -l
    echo "🕵️  Forensics Environment Loaded"
  '';
}
