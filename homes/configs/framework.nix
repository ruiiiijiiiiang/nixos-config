{ consts, ... }:
let
  inherit (consts) ports endpoints;
in
{
  imports = [
    ../modules/files
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "forgejo" = {
        hostname = endpoints.private-repo;
        user = "git";
        port = ports.forgejo.ssh;
      };
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  custom.home = {
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "framework";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "okular.desktop";
      "application/epub+zip" = "okular.desktop";
      "application/x-cbz" = "okular.desktop";
      "application/x-cbr" = "okular.desktop";

      "application/x-7z-compressed" = "ark.desktop";
      "application/x-rar" = "ark.desktop";
      "application/x-tar" = "ark.desktop";
      "application/zip" = "ark.desktop";

      "image/gif" = "gwenview.desktop";
      "image/jpeg" = "gwenview.desktop";
      "image/png" = "gwenview.desktop";
      "image/webp" = "gwenview.desktop";
      "image/svg+xml" = "gwenview.desktop";

      "application/json" = "zeditor.desktop";
      "application/toml" = "zeditor.desktop";
      "application/xml" = "zeditor.desktop";
      "text/csv" = "zeditor.desktop";
      "text/markdown" = "zeditor.desktop";
      "text/plain" = "zeditor.desktop";
      "text/yaml" = "zeditor.desktop";

      "text/html" = "vivaldi-stable.desktop";
      "x-scheme-handler/http" = "vivaldi-stable.desktop";
      "x-scheme-handler/https" = "vivaldi-stable.desktop";
      "x-scheme-handler/about" = "vivaldi-stable.desktop";
      "x-scheme-handler/unknown" = "vivaldi-stable.desktop";

      "x-scheme-handler/tg" = "telegram.desktop";
      "x-scheme-handler/tonsite" = "telegram.desktop";
    };
  };
}
