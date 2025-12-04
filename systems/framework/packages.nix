{ inputs, pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "libxml2-2.13.8" # Required for PacketTracer
    "ciscoPacketTracer8-8.2.2"
  ];

  environment.systemPackages = with pkgs; [
    # --- Terminal Emulators ---
    wezterm

    # --- TUI Applications ---
    inputs.doxx.packages.${pkgs.stdenv.system}.default
    imagemagick
    smassh
    pastel
    superfile
    broot
    posting
    xplr
    gnupg
    gh
    inputs.lazynmap.packages.${pkgs.stdenv.system}.default
    rustscan
    inputs.agenix.packages.${pkgs.stdenv.system}.default

    # --- GUI Applications ---
    inputs.zen-browser.packages.${pkgs.stdenv.system}.default
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
    ciscoPacketTracer8
    wireshark
    telegram-desktop
    protonmail-bridge-gui
    obsidian
    neohtop

    # --- Desktop Environment: Niri (Wayland) ---
    networkmanagerapplet
    rofi
    swaybg
    swaynotificationcenter
    swayidle
    swaylock-effects
    swayosd
    waybar
    brightnessctl
    pavucontrol
    xwayland-satellite
    catppuccin-cursors.frappeLavender
    wl-clipboard

    # --- Desktop Environment: KDE Plasma (Core & Theming) ---
    kdePackages.plasma-pa
    catppuccin-kde

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
    crush
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
  ];

  programs = {
    git.enable = true;
    lazygit.enable = true;
    niri = {
      enable = true;
      useNautilus = false;
    };
    firefox.enable = true;
    steam.enable = true;
    wireshark.enable = true;
    tcpdump.enable = true;
  };

  fonts = {
    enableGhostscriptFonts = true;
    packages = with pkgs; [
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
