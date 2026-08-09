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
  options.custom.roles.workstation.development.packages = with lib; {
    enable = mkEnableOption "Enable development packages";
  };

  config = lib.mkIf cfg.enable {
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
      candy-icons
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
      goofcord
      kdePackages.filelight
      kdePackages.gwenview
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kolourpaint
      kdePackages.ksystemlog
      kdePackages.okular
      kdePackages.yakuake
      kitty
      mission-center
      obsidian
      onlyoffice-desktopeditors
      opencloud-desktop
      protonmail-bridge-gui
      remmina
      simplenote
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
      inputs.llm-agents.packages.${stdenv.hostPlatform.system}.antigravity-cli
      inputs.llm-agents.packages.${stdenv.hostPlatform.system}.codex
      inputs.llm-agents.packages.${stdenv.hostPlatform.system}.copilot-cli
      inputs.llm-agents.packages.${stdenv.hostPlatform.system}.copilot-language-server
      inputs.llm-agents.packages.${stdenv.hostPlatform.system}.opencode
      inputs.windsurf.packages.${stdenv.hostPlatform.system}.codeium-lsp

      # Development Tools
      bash-language-server
      cmake
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
        useNautilus = false;
      };
      nix-index.enable = true;
      obs-studio.enable = true;
      steam.enable = true;
    };

    virtualisation.vmware.host.enable = true;

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
