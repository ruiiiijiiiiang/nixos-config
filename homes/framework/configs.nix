{ lib, helpers, ... }:

let
  inherit (helpers) linkConfig;
  host = "framework";

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
    ]
  );
in
{
  home.file = links;
}
