{
  config,
  consts,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (consts) username;
  cfg = config.custom.roles.workstation.cyber.packages;
in
{
  options.custom.roles.workstation.cyber.packages = with lib; {
    enable = mkEnableOption "Enable cyber role packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Scanning & Recon
      inputs.lazynmap.packages.${stdenv.hostPlatform.system}.default
      masscan
      netcat
      nmap
      seclists
      socat

      # Web Exploitation
      burpsuite
      dirb
      ffuf
      gobuster
      nikto
      sqlmap
      whatweb

      # Password Cracking
      hashcat
      john
      thc-hydra

      # Frameworks
      exploitdb
      metasploit

      # Forensics & Steganography
      binsider
      binwalk
      exiftool
      file
      flare-floss
      poppler-utils
      steghide
      volatility3
      xxd
      zsteg

      # Reverse Engineering
      binaryninja-free
      ghidra-bin
      radare2

      # Misc
      ouch
      python3
      remmina
      unrar
      unzip
    ];

    programs = {
      nix-ld.enable = true;
      wireshark.enable = true;
    };

    systemd.tmpfiles.rules = [
      "L /home/${username}/wordlists - - - - /run/current-system/sw/share/wordlists"
    ];
  };
}
