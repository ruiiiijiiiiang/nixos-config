{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.custom.roles.workstation.packages;
in
{
  options.custom.roles.workstation.packages = with lib; {
    enable = mkEnableOption "Enable workstation packages";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableGhostscriptFonts = true;
      packages = with pkgs; [
        maple-mono.truetype
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [ "maple-mono" ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      atuin
      bottom
      btop
      carapace
      comma
      delta
      fastfetch
      fzf
      gh
      glow
      helix
      inputs.wezterm.packages.${stdenv.hostPlatform.system}.default
      jq
      lazygit
      lsd
      navi
      nix-search-cli
      onefetch
      silver-searcher
      starship
      tldr
      zed-editor
    ];

    programs = {
      bat.enable = true;
      firefox.enable = true;
      fish.enable = true;
      htop.enable = true;
      neovim = {
        enable = true;
        package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      };
      nix-index.enable = true;
      pay-respects.enable = true;
      tcpdump.enable = true;
      yazi.enable = true;
      zoxide.enable = true;
    };
  };
}
