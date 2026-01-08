{ inputs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Recon & networking
    nmap
    masscan
    netcat
    socat
    tcpdump
    tshark

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
  ];

  programs.wireshark.enable = true;
}
