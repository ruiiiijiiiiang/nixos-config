{ config, lib, ... }:

let
  linkConfig =
    { name, paths }:
    builtins.listToAttrs (
      map (path: {
        name = path;
        value.source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${name}/${path}";
      }) paths
    );
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
        name = "rofi";
        paths = [ ".config/rofi" ];
      }
      {
        name = "spicetify";
        paths = [ ".config/spicetify/Themes/text" ];
      }
      {
        name = "starship";
        paths = [ ".config/starship.toml" ];
      }
      {
        name = "superfile";
        paths = [ ".config/superfile" ];
      }
      # {
      #   name = "swaylock";
      #   paths = [ ".config/swaylock" ];
      # }
      # {
      #   name = "swaync";
      #   paths = [ ".config/swaync" ];
      # }
      # {
      #   name = "swayosd";
      #   paths = [ ".config/swayosd" ];
      # }
      # {
      #   name = "waybar";
      #   paths = [ ".config/waybar" ];
      # }
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
