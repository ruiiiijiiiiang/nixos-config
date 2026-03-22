{
  config,
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
  };
}
