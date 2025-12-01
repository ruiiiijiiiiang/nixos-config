{ inputs, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # --- System Core & Essentials ---
    linux-firmware

    # --- System Information & Diagnostics ---
    pciutils
    usbutils
    hwinfo
    fastfetch
    kmon

    # --- System & Process Monitoring ---
    sysstat
    btop
    bottom
    htop
    glances
    iotop
    lsof
    systemctl-tui
    lazyjournal

    # --- Networking & Connectivity ---
    iw
    nmap
    dig
    mtr
    wget

    # --- Disk & Filesystem Utilities ---
    tree
    ncdu
    rsync
    dust
    dysk
    inputs.noxdir.packages.${pkgs.stdenv.system}.default

    # --- Archiving & Compression ---
    unzip
    unrar
    ouch

    # --- General CLI Tools ---
    stow
    tldr
    starship
    atuin
    onefetch
    navi
    carapace
    inputs.file_clipper.packages.${pkgs.stdenv.system}.default

    # --- File & Text Search/Manipulation CLI Tools ---
    fzf
    lsd
    fd
    silver-searcher
    ripgrep
    jq
    yq
    miller
    delta
    glow
    fx
    helix

    # --- Nix-Specific Tools ---
    cachix
    nix-search-cli
    nix-tree
  ];

  programs = {
    nix-index.enable = true;
    command-not-found.enable = false;
    vim.enable = true;
    fish.enable = true;
    htop.enable = true;
    pay-respects.enable = true;
    zoxide.enable = true;
    yazi.enable = true;
    neovim.enable = true;
    bat.enable = true;
    direnv.enable = true;
  };
}
