{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.home.packages;

  headlessPackages = with pkgs; [
    fd
    ripgrep
    systemctl-tui
    tailspin
    inputs.file_clipper.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.witr.packages.${stdenv.system}.default
  ];

  workstationPackages = with pkgs; [
    glow
    nix-search-cli
    onefetch
    silver-searcher
    tldr
  ];

  frameworkPackages = with pkgs; [
    kmon
    lazyjournal

    tree
    ncdu
    dust
    dysk
    inputs.noxdir.packages.${pkgs.stdenv.hostPlatform.system}.default
    unzip
    unrar
    ouch

    stow
    imagemagick
    smassh
    pastel
    superfile
    broot
    posting
    xplr
    gnupg
    doxx
    presenterm
    inputs.lazynmap.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    screen

    yq
    miller
    fx

    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    vivaldi
    mission-center
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.filelight
    kdePackages.kolourpaint
    kdePackages.yakuake
    telegram-desktop
    protonmail-bridge-gui
    neohtop
    vlc
    opencloud-desktop
    remmina
    kitty
    onlyoffice-desktopeditors
    cisco-packet-tracer_9

    easyeffects
    spicetify-cli
    cava

    gcc
    gdb
    lldb
    cmake
    gnumake
    gemini-cli
    github-copilot-cli
    codex
    opencode
    deno
    nodejs
    typescript-language-server
    svelte-language-server
    tailwindcss-language-server
    vscode-langservers-extracted
    vscode-js-debug
    vtsls
    nodePackages.prettier
    rustup
    lua55Packages.luarocks
    stylua
    lua-language-server
    python313
    pyright
    ruff
    python313Packages.debugpy
    uv
    go
    ruby_3_4
    nil
    nixfmt
    statix
    bash-language-server
    shellcheck
    shfmt
    codeium
    yaml-language-server
    taplo
    marksman
    markdownlint-cli2

    cmatrix
    cbonsai
    tty-clock
    astroterm
    pipes

    nix-tree
    nix-inspect
  ];

  cyberPackages = with pkgs; [
    nmap
    masscan
    netcat
    socat

    burpsuite
    sqlmap
    nikto
    gobuster
    dirb
    whatweb
    ffuf

    john
    hashcat
    thc-hydra

    metasploit
    exploitdb

    binwalk
    file
    xxd
    steghide
    exiftool
    binsider
    zsteg
    poppler-utils
    volatility3
    flare-floss

    ghidra-bin
    radare2
    binaryninja-free

    python3
    unzip
    unrar
    ouch
    remmina
    inputs.lazynmap.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  headlessPrograms = {
    atuin.enable = true;
    bat.enable = true;
    btop.enable = true;
    carapace.enable = true;
    delta.enable = true;
    fastfetch.enable = true;
    fzf.enable = true;
    git.enable = true;
    helix.enable = true;
    lazygit.enable = true;
    lsd.enable = true;
    navi.enable = true;
    neovim.enable = true;
    pay-respects.enable = true;
    starship.enable = true;
    wezterm = {
      enable = true;
      package = inputs.wezterm.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    yazi.enable = true;
    zoxide.enable = true;
  };

  workstationPrograms = {
    firefox.enable = true;
    zed-editor.enable = true;
  };

  frameworkPrograms = {
    bottom.enable = true;
    chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };
    direnv.enable = true;
    gh.enable = true;
    htop.enable = true;
    jq.enable = true;
    nix-index.enable = true;
    dsearch.enable = true;
    obsidian.enable = true;
  };

  cyberPrograms = {
    gh.enable = true;
    jq.enable = true;
  };
in
{
  options.custom.home.packages = with lib; {
    roles = mkOption {
      type = types.nullOr (
        types.enum [
          "headless"
          "workstation"
        ]
      );
      default = "headless";
      description = "Install packages and programs based on roles.";
    };

    host = mkOption {
      type = types.nullOr (
        types.enum [
          "framework"
          "vm-cyber"
        ]
      );
      default = null;
      description = "Install packages and programs based on host.";
    };
  };

  config = {
    home.packages =
      headlessPackages
      ++ lib.optionals (cfg.roles == "workstation") workstationPackages
      ++ lib.optionals (cfg.host == "framework") frameworkPackages
      ++ lib.optionals (cfg.host == "vm-cyber") cyberPackages;

    programs =
      headlessPrograms
      // lib.optionalAttrs (cfg.roles == "workstation") workstationPrograms
      // lib.optionalAttrs (cfg.host == "framework") frameworkPrograms
      // lib.optionalAttrs (cfg.host == "vm-cyber") cyberPrograms;
  };
}
