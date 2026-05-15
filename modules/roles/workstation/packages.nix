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

    environment = {
      variables = {
        EDITOR = "nvim";
      };

      systemPackages = with pkgs; [
        bottom
        gh
        glow
        jq
        nix-search-cli
        onefetch
        silver-searcher
        tldr
        zed-editor
      ];
    };

    programs = {
      firefox.enable = true;
      htop.enable = true;
      neovim.package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      nix-index.enable = true;
    };
  };
}
