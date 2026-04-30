{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.custom.roles.workstation.development.packages;
in
{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  options.custom.roles.workstation.development.packages = with lib; {
    enable = mkEnableOption "Enable development packages";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.niri.overlays.niri ];

    environment.systemPackages = with pkgs; [
      iw
      mtr
      nmap
      rsync
      rustscan

      # --- Desktop Environment: Niri ---
      catppuccin-cursors.frappeLavender
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      networkmanagerapplet
      wl-clipboard
      xwayland-satellite

      # --- Desktop Environment: KDE Plasma ---
      catppuccin-kde
      kdePackages.kirigami
      kdePackages.plasma-pa
      kdePackages.qtdeclarative

      # Framework/Workstation specific
      broot
      doxx
      dust
      dysk
      fx
      gnupg
      imagemagick
      inputs.agenix.packages.${stdenv.hostPlatform.system}.default
      inputs.lazynmap.packages.${stdenv.hostPlatform.system}.default
      inputs.rs-top.packages.${stdenv.hostPlatform.system}.default
      kmon
      lazyjournal
      miller
      ncdu
      noxdir
      ouch
      pastel
      posting
      presenterm
      screen
      smassh
      stow
      superfile
      tree
      unrar
      unzip
      xplr
      yq

      # Desktop Apps
      cava
      cisco-packet-tracer_9
      easyeffects
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      kdePackages.filelight
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kolourpaint
      kdePackages.yakuake
      kitty
      mission-center
      neohtop
      obsidian
      onlyoffice-desktopeditors
      opencloud-desktop
      protonmail-bridge-gui
      remmina
      spicetify-cli
      stirling-pdf-desktop
      telegram-desktop
      vivaldi
      vlc

      # Fun stuff
      astroterm
      cbonsai
      cmatrix
      pipes
      tty-clock

      # Nix tools
      nix-inspect
      nix-tree

      # --- Development Tools ---
      bash-language-server
      cmake
      codeium
      codex
      deno
      gcc
      gdb
      gemini-cli
      github-copilot-cli
      gnumake
      go
      lldb
      lua-language-server
      lua55Packages.luarocks
      markdownlint-cli2
      marksman
      nil
      nixfmt
      nodejs
      opencode
      pyright
      python313
      python313Packages.debugpy
      ruby_3_4
      ruff
      rustup
      shellcheck
      shfmt
      statix
      stylua
      svelte-language-server
      tailwindcss-language-server
      taplo
      typescript-language-server
      uv
      vscode-js-debug
      vscode-langservers-extracted
      vtsls
      yaml-language-server
    ];

    programs = {
      command-not-found.enable = false;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      kdeconnect.enable = true;
      niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };
      obs-studio.enable = true;
      steam.enable = true;
      wireshark.enable = true;
    };

    fonts = {
      packages = with pkgs; [
        fira
        google-fonts
        liberation_ttf
        nerd-fonts.symbols-only
        noto-fonts
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
      ];
      fontconfig = {
        defaultFonts = {
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
