{
  config,
  consts,
  inputs,
  lib,
  pkgs,
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
      # Recon & networking
      nmap
      masscan
      netcat
      socat
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
      remmina
    ];

    programs = {
      nix-ld.enable = true;
      tcpdump.enable = true;
      wireshark.enable = true;
    };

    environment.variables = {
      ZED_ALLOW_EMULATED_GPU = "1";
    };

    systemd.tmpfiles.rules = [
      "L /home/${username}/wordlists - - - - /run/current-system/sw/share/wordlists"
    ];
  };
}
