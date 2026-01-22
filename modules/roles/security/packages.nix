{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.security.packages;
in
{
  options.custom.roles.security.packages = with lib; {
    enable = mkEnableOption "Security role packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Recon & networking
      nmap
      masscan
      netcat
      socat
      tshark
      openvas-scanner

      # Web security
      burpsuite
      sqlmap
      nikto
      gobuster
      dirb
      whatweb

      # Passwords & auth
      john
      hashcat

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

      gh
      unzip
      unrar
      ouch
      inputs.lazynmap.packages.${stdenv.system}.default

      networkmanagerapplet
    ];

    programs.tcpdump.enable = true;
    programs.wireshark.enable = true;
  };
}
