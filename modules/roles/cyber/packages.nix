{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.cyber.packages;
in
{
  options.custom.roles.cyber.packages = with lib; {
    enable = mkEnableOption "Cyber role packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Recon & networking
      nmap
      masscan
      netcat
      socat
      openvas-scanner
      wireshark

      # Web security
      burpsuite
      sqlmap
      nikto
      gobuster
      dirb
      whatweb
      ffuf

      # Passwords & auth
      john
      hashcat
      thc-hydra
      seclists

      # Exploitation
      metasploit
      exploitdb

      # Forensics
      binwalk
      file
      xxd
      jq
      steghide
      exiftool
      binsider
      zsteg
      poppler-utils
      volatility3
      flare-floss

      # Reverse Engineering
      ghidra-bin
      radare2
      binaryninja-free

      python3
      gh
      unzip
      unrar
      ouch
      inputs.lazynmap.packages.${stdenv.system}.default

      networkmanagerapplet
      pulseaudio-module-xrdp
      remmina
    ];

    programs.tcpdump.enable = true;
    programs.wireshark.enable = true;
  };
}
