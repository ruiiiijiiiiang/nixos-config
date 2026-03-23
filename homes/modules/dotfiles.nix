{
  config,
  lib,
  helpers,
  dotfilesRoot,
  dotfilesOutOfStore,
  ...
}:
let
  inherit (helpers) linkConfig;
  cfg = config.custom.home.dotfiles;

  mkDotfileLink = attrs: linkConfig ({ inherit dotfilesRoot dotfilesOutOfStore; } // attrs);

  headlessLinks = lib.foldl' lib.recursiveUpdate { } (
    map mkDotfileLink [
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
        name = "kitty";
        paths = [ ".config/kitty" ];
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
        name = "noxdir";
        paths = [ ".noxdir" ];
      }
      {
        name = "nvim";
        paths = [
          {
            src = ".config/nvim-headless";
            target = ".config/nvim";
          }
        ];
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
    ]
  );

  workstationLinks = lib.foldl' lib.recursiveUpdate { } (
    map mkDotfileLink [
      {
        name = "niri";
        paths = [ ".config/niri/config.kdl" ];
      }
      {
        name = "nvim";
        paths = [
          {
            src = ".config/nvim-workstation";
            target = ".config/nvim";
          }
        ];
      }
      {
        name = "zed";
        paths = [ ".config/zed/settings.json" ];
      }
    ]
  );

  archLinks = lib.foldl' lib.recursiveUpdate { } (
    map mkDotfileLink [
      {
        name = "DankMaterialShell";
        paths = [
          {
            src = ".config/DankMaterialShell/settings-arch.json";
            target = ".config/DankMaterialShell/settings.json";
          }
        ];
      }
    ]
  );

  frameworkLinks = lib.foldl' lib.recursiveUpdate { } (
    map mkDotfileLink [
      {
        name = "DankMaterialShell";
        paths = [
          {
            src = ".config/DankMaterialShell/settings-framework.json";
            target = ".config/DankMaterialShell/settings.json";
          }
        ];
      }
    ]
  );
in
{
  options.custom.home.dotfiles = with lib; {
    enable = mkEnableOption "Link dotfiles to home";
    role = mkOption {
      type = types.nullOr (
        types.enum [
          "headless"
          "workstation"
        ]
      );
      default = "headless";
      description = "Link dotfiles based on role.";
    };

    host = mkOption {
      type = types.nullOr (
        types.enum [
          "arch"
          "framework"
        ]
      );
      default = null;
      description = "Link dotfiles based on host.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file =
      headlessLinks
      // lib.optionalAttrs (cfg.role == "workstation") workstationLinks
      // lib.optionalAttrs (cfg.host == "arch") archLinks
      // lib.optionalAttrs (cfg.host == "framework") frameworkLinks;
  };
}
