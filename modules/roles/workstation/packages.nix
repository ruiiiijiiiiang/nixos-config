{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.workstation.packages;
in
{
  options.custom.roles.workstation.packages = with lib; {
    enable = mkEnableOption "Custom gui packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wezterm
      starship
      tldr
      atuin
      fastfetch
      onefetch
      navi
      carapace
      lsd
      btop
      fzf
      silver-searcher
      helix
      delta
      glow
      zed-editor
      nix-search-cli
      inputs.file_clipper.packages.${stdenv.system}.default
    ];

    programs = {
      git.enable = true;
      firefox.enable = true;
      neovim.enable = true;
      fish.enable = true;
      yazi.enable = true;
      zoxide.enable = true;
      bat.enable = true;
      lazygit.enable = true;
      pay-respects.enable = true;
    };

    fonts = {
      enableGhostscriptFonts = true;
      packages = with pkgs; [
        maple-mono.truetype
      ];
    };
  };
}

