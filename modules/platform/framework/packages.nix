{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.platform.framework.packages;
in
{
  options.custom.platform.framework.packages = with lib; {
    enable = mkEnableOption "Framework-specific packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # --- System Information & Diagnostics ---
      pciutils
      usbutils
      hwinfo
      kmon

      # --- System & Process Monitoring ---
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
      inputs.noxdir.packages.${stdenv.system}.default

      # --- Archiving & Compression ---
      unzip
      unrar
      ouch

      # --- Desktop Environment: Niri ---
      networkmanagerapplet
      xwayland-satellite
      catppuccin-cursors.frappeLavender
      wl-clipboard

      # --- Desktop Environment: KDE Plasma ---
      kdePackages.plasma-pa
      catppuccin-kde

      # --- General TUI Tools ---
      stow
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
      presenterm
      inputs.lazynmap.packages.${stdenv.system}.default
      inputs.agenix.packages.${stdenv.system}.default

      # --- File & Text Search/Manipulation CLI Tools ---
      jq
      yq
      miller
      fx

      # --- GUI Applications ---
      inputs.zen-browser.packages.${stdenv.system}.default
      vivaldi
      libreoffice-qt
      mission-center
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.filelight
      kdePackages.kolourpaint
      kdePackages.yakuake
      kdePackages.qtdeclarative
      ungoogled-chromium
      telegram-desktop
      protonmail-bridge-gui
      obsidian
      neohtop
      vlc
      opencloud-desktop
      remmina
      kitty

      # --- Audio & Multimedia ---
      easyeffects
      ncspot
      spicetify-cli
      cava

      # --- Development Tools ---
      # Compilers, Debuggers, Build Systems
      gcc
      gdb
      lldb
      cmake
      gnumake

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
      lua55Packages.luarocks
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
      nix-tree
      nix-inspect
      inputs.colmena.packages.${stdenv.system}.colmena
    ];

    programs = {
      dms-shell.enable = true;
      dsearch.enable = true;
      nix-index.enable = true;
      command-not-found.enable = false;
      htop.enable = true;
      direnv.enable = true;
      niri = {
        enable = true;
        useNautilus = false;
      };
      steam.enable = true;
      wireshark.enable = true;
      tcpdump.enable = true;
      obs-studio.enable = true;
    };

    fonts = {
      enableGhostscriptFonts = true;
      packages = with pkgs; [
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
  };
}
