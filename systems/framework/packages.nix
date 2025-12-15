{ inputs, pkgs, ... }:
with inputs;
with pkgs;
{
  imports = [
    inputs.dankMaterialShell.nixosModules.dankMaterialShell
  ];

  environment.systemPackages = [
    # --- Terminal Emulators ---
    wezterm

    # --- TUI Applications ---
    imagemagick
    smassh
    pastel
    superfile
    broot
    posting
    xplr
    gnupg
    gh
    rustscan
    lazynmap.packages.${stdenv.system}.default
    inputs.doxx.packages.${stdenv.system}.default
    agenix.packages.${stdenv.system}.default

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

    # --- Desktop Environment: Niri (Wayland) ---
    networkmanagerapplet
    vicinae
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
    dms-shell.enable = true;
    firefox.enable = true;
    steam.enable = true;
    wireshark.enable = true;
    tcpdump.enable = true;
    obs-studio.enable = true;
  };

  fonts = {
    enableGhostscriptFonts = true;
    packages = [
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
