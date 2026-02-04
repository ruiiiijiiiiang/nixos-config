{ lib, helper, ... }:

let
  inherit (helper) linkConfig;

  links = lib.mkMerge (
    map linkConfig [
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
