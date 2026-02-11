{ lib, helpers, ... }:

let
  inherit (helpers) linkConfig;
  host = "arch";

  links = lib.mkMerge (
    map linkConfig [
      {
        name = "DankMaterialShell";
        paths = [
          {
            target = ".config/DankMaterialShell/settings.json";
            src = ".config/DankMaterialShell/${host}-settings.json";
          }
        ];
      }
      {
        name = "kitty";
        paths = [ ".config/kitty" ];
      }
      {
        name = "ncspot";
        paths = [ ".config/ncspot" ];
      }
      {
        name = "niri";
        paths = [ ".config/niri" ];
      }
      {
        name = "noxdir";
        paths = [ ".noxdir" ];
      }
      {
        name = "spicetify";
        paths = [ ".config/spicetify/Themes/text" ];
      }
    ]
  );
in
{
  home.file = links;
}
