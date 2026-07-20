{
  config,
  inputs,
  lib,
  pkgs,
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

      # Desktop Environment: Niri
      wl-clipboard
      xwayland-satellite
      catppuccin-cursors.frappeLavender
      inputs.noctalia.packages.${stdenv.hostPlatform.system}.default

      # Desktop Environment: KDE Plasma
      catppuccin-kde
      kdePackages.kirigami
      kdePackages.plasma-pa
      kdePackages.qtdeclarative

      # TUI Apps
      broot
      cava
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
      matcha
      miller
      noxdir
      ouch
      pastel
      posting
      smassh
      spicetify-cli
      stow
      superfile
      tree
      unrar
      unzip
      xplr
      yq

      # Desktop Apps
      easyeffects
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      kdePackages.filelight
      kdePackages.gwenview
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kolourpaint
      kdePackages.okular
      kdePackages.yakuake
      kitty
      mission-center
      obsidian
      onlyoffice-desktopeditors
      opencloud-desktop
      protonmail-bridge-gui
      remmina
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

      # AI
      antigravity-cli
      copilot-language-server
      gemini-cli
      github-copilot-cli
      inputs.windsurf.packages.${stdenv.hostPlatform.system}.codeium-lsp
      opencode

      # Development Tools
      bash-language-server
      cmake
      codex
      distrobox
      gcc
      gdb
      gnumake
      lldb
      lua55Packages.luarocks
      markdownlint-cli2
      marksman
      nodejs
      python3
      rustup
      shellcheck
      shfmt
      uv
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
