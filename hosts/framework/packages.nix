{ inputs, pkgs, ... }:
with inputs;
with pkgs;
{
  imports = [
    inputs.dankMaterialShell.nixosModules.dank-material-shell
  ];

  environment.systemPackages = [
    # --- System Information & Diagnostics ---
    pciutils
    usbutils
    hwinfo
    fastfetch
    kmon

    # --- System & Process Monitoring ---
    btop
    bottom
    sysstat
    lazyjournal

    # --- Networking & Connectivity ---
    iw
    nmap
    dig
    mtr
    wget
    rustscan

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

    # --- Terminal Emulators ---
    wezterm

    # --- Desktop Environment: Niri ---
    networkmanagerapplet
    vicinae
    xwayland-satellite
    catppuccin-cursors.frappeLavender
    wl-clipboard

    # --- Desktop Environment: KDE Plasma ---
    kdePackages.plasma-pa
    catppuccin-kde

    # --- General TUI Tools ---
    starship
    stow
    tldr
    atuin
    onefetch
    navi
    carapace
    imagemagick
    smassh
    pastel
    superfile
    broot
    posting
    xplr
    gnupg
    gh
    doxx
    lazynmap.packages.${stdenv.system}.default
    agenix.packages.${stdenv.system}.default
    file_clipper.packages.${pkgs.stdenv.system}.default

    # --- File & Text Search/Manipulation CLI Tools ---
    fzf
    lsd
    silver-searcher
    jq
    yq
    miller
    delta
    glow
    fx
    helix

    # --- GUI Applications ---
    zen-browser.packages.${stdenv.system}.default
    vivaldi
    zed-editor
    libreoffice-qt
    mission-center
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.filelight
    kdePackages.kolourpaint
    kdePackages.yakuake
    kdePackages.qtdeclarative
    ungoogled-chromium
    wireshark
    telegram-desktop
    protonmail-bridge-gui
    obsidian
    neohtop
    vlc
    mailspring

    # --- Audio & Multimedia ---
    easyeffects
    ncspot
    spicetify-cli
    cava

    # --- Development Tools: Compilers, Debuggers, Build Systems ---
    gcc
    gdb
    lldb
    cmake
    gnumake
    # --- Development Tools: Language Tooling ---

    # AI
    gemini-cli
    github-copilot-cli

    # Web Development
    deno
    nodejs
    typescript-language-server
    svelte-language-server
    tailwindcss-language-server
    vscode-langservers-extracted
    vscode-js-debug
    vtsls
    nodePackages.vscode-json-languageserver
    nodePackages.prettier

    # Rust
    rustup

    # Lua
    lua51Packages.luarocks
    lua54Packages.luarocks
    stylua
    lua-language-server

    # Python
    python313
    pyright
    ruff
    python313Packages.debugpy

    # Go
    go

    # Ruby
    ruby_3_4

    # Nix
    nil
    statix

    # Shell Scripting
    bash-language-server
    shellcheck
    shfmt

    # Other Languages/Tools
    codeium
    yaml-language-server
    taplo
    marksman
    markdownlint-cli2

    # --- Fun & Entertainment ---
    cmatrix
    cbonsai
    tty-clock
    astroterm
    pipes

    # --- Nix-Specific Tools ---
    nix-search-cli
    nix-tree
    inputs.colmena.packages.${stdenv.system}.colmena
  ];

  programs = {
    dms-shell.enable = true;
    firefox.enable = true;
    nix-index.enable = true;
    command-not-found.enable = false;
    neovim.enable = true;
    fish.enable = true;
    htop.enable = true;
    pay-respects.enable = true;
    yazi.enable = true;
    direnv.enable = true;
    zoxide.enable = true;
    git.enable = true;
    bat.enable = true;
    lazygit.enable = true;
    niri = {
      enable = true;
      useNautilus = false;
    };
    steam.enable = true;
    wireshark.enable = true;
    tcpdump.enable = true;
    obs-studio.enable = true;
    kde-pim = {
      enable = true;
      kmail = true;
    };
  };

  fonts = {
    enableGhostscriptFonts = true;
    packages = [
      fira
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-monochrome-emoji
      google-fonts
      nerd-fonts.symbols-only
      maple-mono.truetype
      liberation_ttf
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "maple-mono" ];
        sansSerif = [ "Noto Sans" ];
        serif = [
          "Liberation Serif"
          "Noto Serif"
        ];
      };
    };
  };
}
