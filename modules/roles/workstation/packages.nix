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

      etc."xdg/menus/applications.menu".source =
        "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

      systemPackages = with pkgs; [
        bottom
        comma
        gh
        glow
        jq
        nix-search-cli
        onefetch
        tldr
        zed-editor
      ];
    };

    programs = {
      firefox.enable = true;
      htop.enable = true;
      nix-ld.enable = true;
      neovim.package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      nix-index.enable = true;
    };
  };
}
