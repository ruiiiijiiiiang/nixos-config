{ lib, helper, ... }:

let
  inherit (helper) linkConfig;

  links = lib.mkMerge (
    map linkConfig [
      {
        name = "atuin";
        paths = [ ".config/atuin" ];
      }
      {
        name = "delta";
        paths = [ ".config/delta" ];
      }
      {
        name = "bat";
        paths = [ ".config/bat" ];
      }
      {
        name = "bottom";
        paths = [ ".config/bottom" ];
      }
      {
        name = "btop";
        paths = [ ".config/btop" ];
      }
      {
        name = "fastfetch";
        paths = [ ".config/fastfetch" ];
      }
      {
        name = "fish";
        paths = [ ".config/fish" ];
      }
      {
        name = "git";
        paths = [ ".gitconfig" ];
      }
      {
        name = "helix";
        paths = [ ".config/helix" ];
      }
      {
        name = "lazygit";
        paths = [ ".config/lazygit" ];
      }
      {
        name = "lsd";
        paths = [ ".config/lsd" ];
      }
      {
        name = "nvim";
        paths = [ ".config/nvim" ];
      }
      {
        name = "posting";
        paths = [
          ".config/posting"
          ".local/share/posting/themes"
        ];
      }
      {
        name = "starship";
        paths = [ ".config/starship.toml" ];
      }
      {
        name = "superfile";
        paths = [ ".config/superfile" ];
      }
      {
        name = "wezterm";
        paths = [ ".config/wezterm" ];
      }
      {
        name = "yazi";
        paths = [ ".config/yazi" ];
      }
      {
        name = "zed";
        paths = [ ".config/zed/settings.json" ];
      }
    ]
  );
in
{
  home.file = links;
}
